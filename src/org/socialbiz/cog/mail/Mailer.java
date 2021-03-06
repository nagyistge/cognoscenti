package org.socialbiz.cog.mail;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

public class Mailer {

    Properties emailProperties;

    public Mailer(File propFile) throws Exception {

        if (!propFile.exists()) {
            throw new Exception("The mail properties file does not exist: "+propFile);
        }

        emailProperties = new Properties();
        FileInputStream fis = new FileInputStream(propFile);
        emailProperties.load(fis);
        fis.close();

    }

    public String getProperty(String key) {
        return emailProperties.getProperty(key);
    }

    public Properties getProperties() {
        return emailProperties;
    }

}
