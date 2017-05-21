<!DOCTYPE xsl:stylesheet [

    <!ENTITY nbsp       "&#160;">

]>

<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:f="urn:stylesheet-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:img="http://www.gutenberg.ph/2006/schemas/imageinfo"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    version="2.0"
    exclude-result-prefixes="f img xd xs"
    >

    <xd:doc type="stylesheet">
        <xd:short>TEI stylesheet to handle figures.</xd:short>
        <xd:detail>This stylesheet handles TEI figure elements; part of tei2html.xsl.</xd:detail>
        <xd:author>Jeroen Hellingman</xd:author>
        <xd:copyright>2016, Jeroen Hellingman</xd:copyright>
    </xd:doc>


    <xd:doc type="string">
        The imageInfoFile is an XML file that contains information on the dimensions of images.
        This file is generated by an external tool.
    </xd:doc>

    <xsl:param name="imageInfoFile" as="xs:string?"/>

    <xsl:variable name="imageInfo" select="document(normalize-space($imageInfoFile), .)" as="node()?"/>

    <xd:doc>
        <xd:short>Determine the file name for an image.</xd:short>
        <xd:detail>
            <p>Derive a file name from the <code>@id</code> attribute, and assume that the extension
            is <code>.jpg</code>, unless an alternative name is given in the <code>@rend</code> attribute, using
            the rendition-ladder notation <code>image()</code>.</p>
        </xd:detail>
        <xd:param name="format" type="string">The default file-extension of the image file.</xd:param>
    </xd:doc>

    <xsl:template name="getimagefilename">
        <xsl:param name="format" select="'.jpg'" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="f:has-rend-value(@rend, 'image')">
                <xsl:value-of select="f:rend-value(@rend, 'image')"/>
            </xsl:when>
            <xsl:when test="@url">
                <xsl:value-of select="@url"/>
                <xsl:copy-of select="f:logWarning('Using non-standard attribute url {1} on figure.', (@url))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('images/', @id, $format)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xd:doc>
        <xd:short>Determine the file name for an image.</xd:short>
        <xd:detail>
            <p>Derive a file name from the <code>@id</code> attribute, and assume that the extension
            is <code>.jpg</code>, unless an alternative name is given in the <code>@rend</code> attribute, using
            the rendition-ladder notation <code>image()</code>.</p>

            <p>This function should replace the similarly named named template.</p>
        </xd:detail>
        <xd:param name="node" type="node()">The figure element for which the file name needs to be determined.</xd:param>
        <xd:param name="defaultformat" type="string">The default file-extension of the image file.</xd:param>
    </xd:doc>

    <xsl:function name="f:getimagefilename" as="xs:string">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="defaultformat" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="f:has-rend-value($node/@rend, 'image')">
                <xsl:value-of select="f:rend-value($node/@rend, 'image')"/>
            </xsl:when>
            <xsl:when test="$node/@url">
                <xsl:value-of select="$node/@url"/>
                <xsl:copy-of select="f:logWarning('Using non-standard attribute url {1} on figure.', ($node/@url))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('images/', $node/@id, $defaultformat)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xd:doc>
        <xd:short>Insert an image in the output (step 1).</xd:short>
        <xd:detail>
            <p>Insert all the required output for an inline image in HTML.</p>

            <p>This template generates the elements surrounding the actual image tag in the output.</p>
        </xd:detail>
        <xd:param name="alt" type="string">The text to be placed on the HTML alt attribute.</xd:param>
        <xd:param name="format" type="string">The default file-extension of the image file.</xd:param>
    </xd:doc>

    <xsl:template name="insertimage">
        <xsl:param name="alt" select="''" as="xs:string"/>
        <xsl:param name="format" select="'.jpg'" as="xs:string"/>

        <!-- Should we link to an external image? -->
        <xsl:choose>
            <xsl:when test="f:has-rend-value(@rend, 'link')">
                <xsl:variable name="url" select="f:rend-value(@rend, 'link')"/>
                <xsl:call-template name="verify-linked-image">
                    <xsl:with-param name="url" select="$url"/>
                </xsl:call-template>
                <a>
                    <xsl:choose>
                        <xsl:when test="$outputformat = 'epub' and matches($url, '^[^:]+\.(jpg|png|gif|svg)$')">
                            <!-- cannot directly link to image file in epub, need to generate wrapper html
                                 and link to that. -->
                            <xsl:call-template name="generate-image-wrapper">
                                <xsl:with-param name="imagefile" select="$url"/>
                            </xsl:call-template>
                            <xsl:attribute name="href"><xsl:value-of select="$basename"/>-<xsl:value-of select="f:generate-id(.)"/>.xhtml</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="href">
                                <xsl:value-of select="$url"/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:call-template name="insertimage2">
                        <xsl:with-param name="alt" select="$alt" as="xs:string"/>
                        <xsl:with-param name="format" select="$format" as="xs:string"/>
                    </xsl:call-template>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="insertimage2">
                    <xsl:with-param name="alt" select="$alt" as="xs:string"/>
                    <xsl:with-param name="format" select="$format" as="xs:string"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xd:doc>
        <xd:short>Verify an image linked to is actually present in the imageinfo file.</xd:short>
    </xd:doc>

    <xsl:template name="verify-linked-image">
        <xsl:param name="url"/>

        <xsl:variable name="width">
            <xsl:value-of select="substring-before($imageInfo/img:images/img:image[@path=$url]/@width, 'px')"/>
        </xsl:variable>
        <xsl:if test="$width = ''">
            <xsl:copy-of select="f:logWarning('Linked image {1} not in image-info file {2}.', ($url, normalize-space($imageInfoFile)))"/>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Insert an image in the output (step 2).</xd:short>
        <xd:detail>
            <p>Insert the actual <code>img</code>-element in the output HTML.</p>
        </xd:detail>
        <xd:param name="alt" type="string">The text to be placed on the HTML alt attribute.</xd:param>
        <xd:param name="format" type="string">The default file-extension of the image file.</xd:param>
        <xd:param name="filename" type="string">The name of the image file (may be left empty).</xd:param>
    </xd:doc>

    <xsl:template name="insertimage2">
        <xsl:param name="alt" select="''" as="xs:string"/>
        <xsl:param name="format" select="'.jpg'" as="xs:string"/>
        <xsl:param name="filename" select="''" as="xs:string"/>

        <xsl:variable name="alt" select="if (figDesc) then figDesc else $alt" as="xs:string"/>
        <xsl:variable name="file" select="if ($filename != '') then $filename else f:getimagefilename(., $format)" as="xs:string"/>
        <xsl:variable name="width" select="substring-before($imageInfo/img:images/img:image[@path=$file]/@width, 'px')"/>
        <xsl:variable name="height" select="substring-before($imageInfo/img:images/img:image[@path=$file]/@height, 'px')"/>
        <xsl:variable name="fileSize" select="$imageInfo/img:images/img:image[@path=$file]/@filesize"/>

        <xsl:if test="$width = ''">
            <xsl:copy-of select="f:logWarning('Image {1} not in image-info file {2}.', ($file, normalize-space($imageInfoFile)))"/>
        </xsl:if>
        <xsl:if test="$width != '' and number($width) > 720">
            <xsl:copy-of select="f:logWarning('Image {1} width more than 720 pixels ({2} px).', ($file, $width))"/>
        </xsl:if>
        <xsl:if test="$height != '' and number($height) > 720">
            <xsl:copy-of select="f:logWarning('Image {1} height more than 720 pixels ({2} px).', ($file, $height))"/>
        </xsl:if>
        <xsl:if test="$fileSize != '' and number($fileSize) > 102400">
            <xsl:copy-of select="f:logWarning('Image {1} file-size more than 100 kilobytes ({2} kB).', ($file, xs:string(ceiling(number($fileSize) div 1024))))"/>
        </xsl:if>

        <img src="{$file}" alt="{$alt}">
            <xsl:if test="$width != ''">
                <xsl:attribute name="width">
                    <xsl:value-of select="$width"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$height != ''">
                <xsl:attribute name="height">
                    <xsl:value-of select="$height"/>
                </xsl:attribute>
            </xsl:if>
        </img>
    </xsl:template>


    <xd:doc>
        <xd:short>Generate an image wrapper for ePub.</xd:short>
        <xd:detail>
            <p>Since images may not appear stand-alone in an ePub file, this generates
            an HTML wrapper for (mostly large) images linked to from a smaller image using
            <code>link()</code> in the <code>@rend</code> attribute.</p>
        </xd:detail>
        <xd:param name="imagefile" type="string">The name of the image file (may be left empty).</xd:param>
    </xd:doc>

    <xsl:template name="generate-image-wrapper">
        <xsl:param name="imagefile" as="xs:string"/>

        <xsl:variable name="filename"><xsl:value-of select="$basename"/>-<xsl:value-of select="f:generate-id(.)"/>.xhtml</xsl:variable>

        <xsl:variable name="alt">
            <xsl:choose>
                <xsl:when test="figDesc">
                    <xsl:value-of select="figDesc"/>
                </xsl:when>
                <xsl:when test="head">
                    <xsl:value-of select="head"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:result-document href="{$path}/{$filename}">
            <xsl:copy-of select="f:logInfo('Generated image wrapper file: {1}/{2}.', ($path, $filename))"/>
            <html>
                <xsl:call-template name="generate-html-header"/>
                <body>
                    <div class="figure">
                        <img src="{$imagefile}" alt="{$alt}"/>
                        <xsl:apply-templates/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>


    <!-- TEI P5 graphic element -->
    <xsl:template match="graphic">
        <xsl:if test="f:isSet('includeImages')">
            <xsl:call-template name="insertimage">
                <xsl:with-param name="format" select="'.png'"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Handle an in-line image.</xd:short>
        <xd:detail>
            <p>Special handling of figures marked as inline using the rend attribute.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure[@rend='inline' or f:rend-value(@rend, 'position') = 'inline']">
        <xsl:if test="f:isSet('includeImages')">
            <xsl:call-template name="insertimage">
                <xsl:with-param name="format" select="'.png'"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Generate CSS code related to images.</xd:short>
        <xd:detail>
            <p>In the CSS for each image, we register its length and width, to help HTML rendering.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure" mode="css">
        <xsl:if test="f:isSet('includeImages')">
            <xsl:call-template name="generate-css-rule"/>
            <xsl:call-template name="generate-image-width-css-rule"/>
            <xsl:apply-templates mode="css"/>
        </xsl:if>
    </xsl:template>


    <xsl:template match="figure[@rend='inline' or f:rend-value(@rend, 'position') = 'inline']" mode="css">
        <xsl:if test="f:isSet('includeImages')">
            <xsl:call-template name="generate-css-rule"/>
            <xsl:call-template name="generate-image-width-css-rule">
                <xsl:with-param name="format" select="'.png'"/>
            </xsl:call-template>
            <xsl:apply-templates mode="css"/>
        </xsl:if>
    </xsl:template>


    <xsl:template name="generate-image-width-css-rule">
        <xsl:param name="format" select="'.jpg'"/>

        <!-- Create a special CSS rule for setting the width of this image -->
        <xsl:variable name="file" select="f:getimagefilename(., $format)" as="xs:string"/>
        <xsl:variable name="width" select="$imageInfo/img:images/img:image[@path=$file]/@width" as="xs:string?"/>

        <xsl:if test="$width != ''">
.<xsl:value-of select="f:generate-id(.)"/>width {
width:<xsl:value-of select="$width"/>;
}
</xsl:if>

    </xsl:template>


    <xd:doc>
        <xd:short>Handle a figure element.</xd:short>
        <xd:detail>
            <p>This template handles the figure element. It takes care of both the figure annotations (title, legenda, etc.)
            and the in-line loading of the image in HTML.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure">
        <xsl:if test="f:isSet('includeImages')">
            <xsl:if test="not(f:rend-value(@rend, 'position') = 'abovehead')">
                <!-- figure will be rendered outside a paragraph context if position is abovehead. -->
                <xsl:call-template name="closepar"/>
            </xsl:if>
            <div class="figure">
                <xsl:copy-of select="f:set-lang-id-attributes(.)"/>

                <xsl:variable name="file" select="f:getimagefilename(., '.jpg')" as="xs:string"/>
                <xsl:variable name="width" select="$imageInfo/img:images/img:image[@path=$file]/@width" as="xs:string?"/>

                <xsl:variable name="class">
                    <xsl:text>figure </xsl:text>
                    <xsl:if test="f:rend-value(@rend, 'float') = 'left'">floatLeft </xsl:if>
                    <xsl:if test="f:rend-value(@rend, 'float') = 'right'">floatRight </xsl:if>

                    <!-- Add the class that sets the width, if the width is known -->
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:variable>
                <xsl:copy-of select="f:set-class-attribute-with(., $class)"/>

                <xsl:call-template name="figure-head-top"/>
                <xsl:call-template name="figure-annotations-top"/>

                <xsl:call-template name="insertimage">
                    <xsl:with-param name="alt" select="if (figDesc) then figDesc else (if (head) then head else '')"/>
                </xsl:call-template>

                <xsl:call-template name="figure-annotations-bottom"/>
                <xsl:apply-templates/>
            </div>
            <xsl:if test="not(f:rend-value(@rend, 'position') = 'abovehead')">
                <xsl:call-template name="reopenpar"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>


    <xsl:template name="figure-head-top">
        <xsl:if test="head[f:positionAnnotation(@rend) = 'figTop']">
            <xsl:apply-templates select="head[f:positionAnnotation(@rend) = 'figTop']" mode="figAnnotation"/>
        </xsl:if>
    </xsl:template>


    <xsl:template name="figure-annotations-top">
        <xsl:if test="p[f:hasTopPositionAnnotation(@rend)]">

            <xsl:variable name="file" select="f:getimagefilename(., '.jpg')" as="xs:string"/>
            <xsl:variable name="width" select="$imageInfo/img:images/img:image[@path=$file]/@width" as="xs:string?"/>

            <div>
                <xsl:attribute name="class">
                    <xsl:text>figAnnotation </xsl:text>
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:attribute>

                <xsl:if test="p[f:positionAnnotation(@rend) = 'figTopLeft']">
                    <span class="figTopLeft"><xsl:apply-templates select="p[@type='figTopLeft' or f:rend-value(@rend, 'position') = 'figTopLeft']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="p[f:positionAnnotation(@rend) = 'figTop']">
                    <span class="figTop"><xsl:apply-templates select="p[@type='figTop' or f:rend-value(@rend, 'position') = 'figTop']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="not(p[f:positionAnnotation(@rend) = 'figTop'])">
                    <span class="figTop"><xsl:text>&nbsp;</xsl:text></span>
                </xsl:if>
                <xsl:if test="p[f:positionAnnotation(@rend) = 'figTopRight']">
                    <span class="figTopRight"><xsl:apply-templates select="p[@type='figTopRight' or f:rend-value(@rend, 'position') = 'figTopRight']" mode="figAnnotation"/></span>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:template name="figure-annotations-bottom">
        <xsl:if test="p[f:hasBottomPositionAnnotation(@rend)]">

            <xsl:variable name="file" select="f:getimagefilename(., '.jpg')" as="xs:string"/>
            <xsl:variable name="width" select="$imageInfo/img:images/img:image[@path=$file]/@width" as="xs:string?"/>

            <div>
                <xsl:attribute name="class">
                    <xsl:text>figAnnotation </xsl:text>
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:attribute>

                <xsl:if test="p[f:positionAnnotation(@rend) = 'figBottomLeft']">
                    <span class="figBottomLeft"><xsl:apply-templates select="p[@type='figBottomLeft' or f:rend-value(@rend, 'position') = 'figBottomLeft']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="p[f:positionAnnotation(@rend) = 'figBottom']">
                    <span class="figBottom"><xsl:apply-templates select="p[@type='figBottom' or f:rend-value(@rend, 'position') = 'figBottom']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="not(p[f:positionAnnotation(@rend) = 'figBottom'])">
                    <span class="figTop"><xsl:text>&nbsp;</xsl:text></span>
                </xsl:if>
                <xsl:if test="p[f:positionAnnotation(@rend) = 'figBottomRight']">
                    <span class="figBottomRight"><xsl:apply-templates select="p[@type='figBottomRight' or f:rend-value(@rend, 'position') = 'figBottomRight']" mode="figAnnotation"/></span>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:function name="f:hasPositionAnnotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:value-of select="f:positionAnnotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:hasTopPositionAnnotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:value-of select="f:topPositionAnnotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:hasBottomPositionAnnotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:value-of select="f:bottomPositionAnnotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:positionAnnotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:variable name="position" select="substring-before(substring-after($rend, 'position('), ')')"/>

        <xsl:value-of select="if ($position = 'figTopLeft' or $position = 'figTop' or $position = 'figTopRight'
                                or $position = 'figBottomLeft' or $position = 'figBottom' or $position = 'figBottomRight') then $position else ''"/>
    </xsl:function>

    <xsl:function name="f:topPositionAnnotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:variable name="position" select="substring-before(substring-after($rend, 'position('), ')')"/>

        <xsl:value-of select="if ($position = 'figTopLeft' or $position = 'figTop' or $position = 'figTopRight') then $position else ''"/>
    </xsl:function>

    <xsl:function name="f:bottomPositionAnnotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>

        <xsl:variable name="position" select="substring-before(substring-after($rend, 'position('), ')')"/>

        <xsl:value-of select="if ($position = 'figBottomLeft' or $position = 'figBottom' or $position = 'figBottomRight') then $position else ''"/>
    </xsl:function>

    <xsl:template match="figure/head[not(f:hasPositionAnnotation(@rend))]">
        <p class="figureHead"><xsl:apply-templates/></p>
    </xsl:template>


    <xsl:template match="figure/head[f:hasPositionAnnotation(@rend)]"/>


    <xsl:template match="p[f:hasPositionAnnotation(@rend)]"/>


    <xsl:template match="figure/head[f:hasPositionAnnotation(@rend)]" mode="figAnnotation">
        <p class="figureHead"><xsl:apply-templates/></p>
    </xsl:template>


    <xsl:template match="p[f:hasPositionAnnotation(@rend)]" mode="figAnnotation">
        <xsl:apply-templates/>
    </xsl:template>


    <xsl:template match="figDesc"/>


</xsl:stylesheet>
