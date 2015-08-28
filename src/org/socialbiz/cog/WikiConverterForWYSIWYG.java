/*
 * Copyright 2013 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors Include: Shamim Quader, Sameer Pradhan, Kumar Raja, Jim Farris,
 * Sandia Yang, CY Chen, Rajiv Onat, Neal Wang, Dennis Tam, Shikha Srivastava,
 * Anamika Chaudhari, Ajay Kakkar, Rajeev Rastogi
 */

package org.socialbiz.cog;

import java.io.StringWriter;
import java.util.Vector;

/**
 * This is a sub class of WikiConverter that handles the HTML to WIKI conversion
 * for new Editor.
 *
 * Because of threading issues, a new instance should be created on every
 * thread.  This is done for you by using writeWikiAsHtml method for conversion.
 * Constructor is private, so use writeWikiAsHtml instead.
 */
public class WikiConverterForWYSIWYG extends WikiConverter
{
    /**
    * Don't construct.  Just use writeWikiAsHtml instead.
    */
    private WikiConverterForWYSIWYG(AuthRequest destination)
    {
        super( destination );
    }


    /**
    * Static version create the object instance and then calls the
    * converter directly.   Convenience for the case where you are
    * going to use a converter only once, and only for HTML output.
    */
    public static String makeHtmlString(AuthRequest destination, String tv) throws Exception
    {
        StringWriter strWriter = new StringWriter();
        AuthDummy dummy = new AuthDummy(destination.getUserProfile(), strWriter, destination.getCogInstance());
        WikiConverterForWYSIWYG wc = new WikiConverterForWYSIWYG(dummy);
        wc.writeWikiAsHtml(tv);
        return strWriter.toString();
    }



    /**
    * Static version create the object instance and then calls the
    * converter directly.   Convenience for the case where you are
    * going to use a converter only once, and only for HTML output.
    */
    public static void writeWikiAsHtml(AuthRequest destination, String tv) throws Exception
    {
        WikiConverterForWYSIWYG wc = new WikiConverterForWYSIWYG(destination);
        wc.writeWikiAsHtml(tv);
    }


    public void outputProperLink(String linkURL)
        throws Exception
    {
        int barPos = linkURL.indexOf("|");
        String linkText = linkURL.trim();
        String linkAddr = null;

        if (barPos >= 0) {
            //We have both a link text, and a link address, so use them.
            linkText = linkURL.substring(0,barPos).trim();
            linkAddr = linkURL.substring(barPos+1).trim();
        }
        else {
            //This is the case that we have no bar char, and thus no link address.
            //The address is then derived from the text, one of two ways:
            //
            // 1. if there is a slash, and it starts with http, then the text itself is
            //    assumed to be a URL and the text value is used as a URL without modification.
            //
            // 2. otherwise it is assumed to a symbolic name in the
            //    such as a site or project name, so look up the address of the project
            //    and include the URL there.  There was a time that you could just type
            //    the name of a project in, and get a link to it.
            //    Here we do conversion to put the link to the project in, if it
            //    exits.
            //
            // After editing there should always be a link and we will not go through
            // this again.
            //
            if (linkText.startsWith("http") && linkText.indexOf("/")>0) {
                linkAddr = linkText;
            }
            else {
                Vector<NGPageIndex> foundPages = ar.getCogInstance().getPageIndexByName(linkText);
                if (foundPages.size() >= 1) {
                    NGPageIndex foundPI = foundPages.firstElement();
                    linkAddr = ar.baseURL + ar.getResourceURL(foundPI, "notesList.htm");
                }
                else {
                    //didn't find a project with that name, so just link to hash which
                    //works out to be the current page
                    linkAddr="#";
                }
            }
        }

        ar.write("<a href=\"");
        ar.write(linkAddr);
        ar.write("\">");
        ar.writeHtml(linkText);
        ar.write("</a>");
    }

    protected void makeLineBreak()
        throws Exception
    {
        ar.write("<br>");
    }

    protected void makeHorizontalRule()
        throws Exception
    {
        ar.write("<hr>");
    }

    /**
    * Currently tags are output to the editor simply as text that can be
    * edited, and not as a hyperlink.   Later, we might have
    * some special coding to allow for a nice tag editor.
    */
    protected void outputTagLink(String tagName)
        throws Exception
    {
        ar.write("#");
        ar.writeURLData(tagName);
    }

}