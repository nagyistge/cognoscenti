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

package org.socialbiz.cog.test;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import org.socialbiz.cog.DOMFace;

public class TemplateURLRecord extends DOMFace
{

    public TemplateURLRecord(Document doc, Element ele, DOMFace p)
    {
        super(doc, ele, p);
    }

    public String getTestableUrl()
        throws Exception
    {
        return getScalar("url");
    }
    public void setTestableUrl(String url)
        throws Exception
    {
        setScalar("url", url);
    }


}
