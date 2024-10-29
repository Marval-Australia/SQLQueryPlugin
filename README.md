# SQL Retrieval Plugin

This plugin will allow you to retrieve information directly from the Marval database and return it in a JSON format.

## Compatible Versions

| Plugin  | MSM            |
|---------|----------------|
| 0.x     | 14.x           |
| 0.x     | 15.x           |

## Installation

Once the plugin has been installed you may need to enter the database connection details. These connection details can be obtained from the server, however under some circumstances, this may not work.
You will need to complete the folowing attributes which get passed to an internal database connection string.

+ *DBConnectionString* : The connection string, ie (without the quotes) "Data Source=dbhost;Initial Catalog=dataabasename;Integrated Security=False;User ID=dbusername;Password=userpassword"

The connection string exists in the file connectionStrings.config in your Marval directory.
If your Marval directory is C:\Program Files\Marval Software\MSM\ the the file will be C:\Program Files\Marval Software\MSM\connectionStrings.config

## Usage



## Contributing

We welcome all feedback including feature requests and bug reports.