package org.cysecurity.cspf.jvl.model;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

public class DBConnect {

    private static volatile DataSource pooledDataSource;

    public Connection connect(String path) throws IOException, ClassNotFoundException, SQLException {
        DataSource ds = lookupPool();
        if (ds != null) {
            return ds.getConnection();
        }
        return legacyConnect(path);
    }

    private static DataSource lookupPool() {
        DataSource ds = pooledDataSource;
        if (ds != null) {
            return ds;
        }
        synchronized (DBConnect.class) {
            if (pooledDataSource == null) {
                try {
                    Context envCtx = (Context) new InitialContext().lookup("java:comp/env");
                    pooledDataSource = (DataSource) envCtx.lookup("jdbc/jvl");
                } catch (NamingException e) {
                    return null;
                }
            }
            return pooledDataSource;
        }
    }

    private static Connection legacyConnect(String path) throws IOException, ClassNotFoundException, SQLException {
        Properties properties = new Properties();
        FileInputStream in = new FileInputStream(path);
        try {
            properties.load(in);
        } finally {
            in.close();
        }
        String dbuser = properties.getProperty("dbuser");
        String dbpass = properties.getProperty("dbpass");
        String dbfullurl = properties.getProperty("dburl") + properties.getProperty("dbname");
        String jdbcdriver = properties.getProperty("jdbcdriver");
        Class.forName(jdbcdriver);
        return DriverManager.getConnection(dbfullurl, dbuser, dbpass);
    }
}
