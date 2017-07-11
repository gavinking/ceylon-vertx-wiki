String sqlCreatePagesTable = "create table if not exists Pages (Id integer identity primary key, Name varchar(255) unique, Content clob)";
String sqlGetPage = "select Id, Content from Pages where Name = ?";
String sqlCreatePage = "insert into Pages values (NULL, ?, ?)";
String sqlSavePage = "update Pages set Content = ? where Id = ?";
String sqlAllPages = "select Name from Pages";
String sqlDeletePage = "delete from Pages where Id = ?";
