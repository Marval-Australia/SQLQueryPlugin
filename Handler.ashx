<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.IO;
using System.Net;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Serialization;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using Serilog;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Web.Script.Serialization;
using System.Web;
using MarvalSoftware.UI.WebUI.ServiceDesk.RFP.Plugins;
using System.Linq;
using System.Data;
using System.Data.SqlClient;
using Microsoft.Win32;
using MarvalSoftware.Security;

public class Handler : PluginHandler
{

    private string APIKey { get; set; }
    private string Password { get; set; }
    private string Username { get; set; }
    private string Host { get; set; }
    private string DBName { get; set; }
    private string MarvalHost { get; set; }
    private string AssignmentGroups { get; set; }
    private string ExcludeDescriptionMatch { get; set; }                            
    private string DBConnectionStringFromConfig { get { return this.GlobalSettings["DBConnectionString"]; } }
    private int MsmRequestNo { get; set; }
    private string SQLQueryMapping { get; set; }    
    private int lastLocation { get; set; }
    private string TagQueryValue { get; set; }
    public override bool IsReusable { get { return false; } }
    
    private string GetDBString()
{
    string connectionString = "";
    if (!string.IsNullOrEmpty(DBConnectionStringFromConfig))
    {
        return DBConnectionStringFromConfig;
    }
    string msmdLocation = GetAppPath("MSM");
    string path = msmdLocation;
    string newPath = Path.GetFullPath(Path.Combine(path, @"..\"));
    string openFilePath = newPath + "connectionStrings.config";
    XmlDocument xmlDoc = new XmlDocument();
    xmlDoc.Load(openFilePath);

    XmlNodeList nodeList = xmlDoc.SelectNodes("/appSettings/add[@key='DatabaseConnectionString']");
    
    if (nodeList.Count > 0)
    {
        connectionString = nodeList[0].Attributes["value"].Value;
    }
    else
    {
        Log.Information("Could not find connection string on the local machine");
    }
    return connectionString;
}
    private string GetAppPath(string productName)
    {
        const string foldersPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders";
        var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);

        var subKey = baseKey.OpenSubKey(foldersPath);
        if (subKey == null)
        {
            baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32);
            subKey = baseKey.OpenSubKey(foldersPath);
        }
        return subKey != null ? subKey.GetValueNames().FirstOrDefault(kv => kv.Contains(productName)) : "ERROR";
    }

    private string GetSQLResponse(string SQLQuery)
    {
        var userid = User.CurrentUser.Identifier;                    
        var userid2 = userid.ToString();     
        SQLQuery = SQLQuery.Replace("@@UserId", userid2);
        if (!SQLQuery.TrimStart().StartsWith("SELECT", StringComparison.OrdinalIgnoreCase) ||
        SQLQuery.IndexOf("UPDATE", StringComparison.OrdinalIgnoreCase) >= 0 ||
        SQLQuery.IndexOf("DELETE", StringComparison.OrdinalIgnoreCase) >= 0 ||
        SQLQuery.IndexOf("DROP", StringComparison.OrdinalIgnoreCase) >= 0 ||
        SQLQuery.IndexOf("ALTER", StringComparison.OrdinalIgnoreCase) >= 0)
    {
        string responseS = "{\"error\": \"Your query is possibly dangerous, please only run SELECT queries.\"}";
         return (responseS);
    }
        List<object> content = new List<object>();
        string connString = GetDBString();
        using (SqlConnection conn = new SqlConnection())
        {
            conn.ConnectionString = connString;
            using (SqlCommand cmd = new SqlCommand())
            {
                cmd.CommandText = SQLQuery;
                cmd.Connection = conn;
                try {
                conn.Open();
                 using (SqlDataReader sdr = cmd.ExecuteReader())
                {
                    while (sdr.Read())
                    {
                        Dictionary<string, object> row = new Dictionary<string, object>();
                        for (int i = 0; i < sdr.FieldCount; i++)
                        {
                            row[sdr.GetName(i)] = sdr.GetValue(i);
                        }
                        content.Add(row);
                    }
                }
                } catch (SqlException ex) {
                        return "SQL Error: "+  ex.Message;
                }
                finally
            {
                conn.Close();
            }
            }
            JavaScriptSerializer serializer = new JavaScriptSerializer
    {
        MaxJsonLength = Int32.MaxValue
    };
    return serializer.Serialize(content);
        
        }
    }
    
    public override void HandleRequest(HttpContext context)
    {
        var param = context.Request.HttpMethod;  

        MsmRequestNo = !string.IsNullOrWhiteSpace(context.Request.Params["requestNumber"]) ? int.Parse(context.Request.Params["requestNumber"]) : 0;
        lastLocation = !string.IsNullOrWhiteSpace(context.Request.Params["lastLocation"]) ? int.Parse(context.Request.Params["lastLocation"]) : 0;
        TagQueryValue = context.Request.Params["tag"] ?? string.Empty;

        this.MarvalHost = context.Request.Params["host"] ?? string.Empty;
        
        SQLQueryMapping = this.GlobalSettings["SQLQueryMapping"];

        switch (param)
        {
         case "GET":
       if (!string.IsNullOrEmpty(TagQueryValue)) {
        
           var deserializedObject = JsonConvert.DeserializeObject<Dictionary<string, List<List<string>>>>(SQLQueryMapping);
           var items = deserializedObject["items"];
           foreach (var item in items)
           {
                Log.Information("Tag name is " + item[0]);
                Log.Information("Query is " + item[1]);
                if (TagQueryValue == item[0])  {
                    Log.Information("Based on the tag name, I'm running query" + item[1]);
                    string json = this.GetSQLResponse(item[1]); 
                   context.Response.Write(json);
                }
            }
       } else {
               context.Response.Write("No valid parameter requested");
        }
        
           break;
           case "POST":
           break;
       }
    }
}

