<!DOCTYPE xsl:stylesheet [

    <!ENTITY tab        "&#x09;">
    <!ENTITY lf         "&#x0A;">
    <!ENTITY cr         "&#x0D;">
    <!ENTITY deg        "&#176;">
    <!ENTITY ldquo      "&#x201C;">
    <!ENTITY lsquo      "&#x2018;">
    <!ENTITY rdquo      "&#x201D;">
    <!ENTITY rsquo      "&#x2019;">
    <!ENTITY nbsp       "&#160;">
    <!ENTITY mdash      "&#x2014;">
    <!ENTITY prime      "&#x2032;">
    <!ENTITY Prime      "&#x2033;">
    <!ENTITY plusmn     "&#x00B1;">
    <!ENTITY frac14     "&#x00BC;">
    <!ENTITY frac12     "&#x00BD;">
    <!ENTITY frac34     "&#x00BE;">

]>
<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:f="urn:stylesheet-functions"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    exclude-result-prefixes="f xhtml xs xd"
    version="2.0"
    >

    <xd:doc type="stylesheet">
        <xd:short>Stylesheet to perform various checks on a TEI file.</xd:short>
        <xd:detail>This stylesheet performs a number of checks on a TEI file, to help find potential issues with both the text and tagging.</xd:detail>
        <xd:author>Jeroen Hellingman</xd:author>
        <xd:copyright>2012, Jeroen Hellingman</xd:copyright>
    </xd:doc>


    <xsl:template match="divGen[@type='check']">


    </xsl:template>


    <xsl:template match="/">

        <!-- page numbers in sequence -->

        <!-- page numbers in odd places -->

        <!-- division numbers in sequence -->

        <!-- quotation marks matching -->

        <xsl:apply-templates mode="checks"/>
    </xsl:template>


    <xsl:template mode="checks" match="i | b | sc | uc | tt">
        <xsl:message terminate="no"><xsl:value-of select="f:line-number(.)"/> Warning: contains non-TEI element <xsl:value-of select="name()"/></xsl:message>
        <xsl:apply-templates mode="checks"/>
    </xsl:template>


    <xsl:template mode="checks" match="p">
        <xsl:call-template name="match-punctuation-pairs">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template mode="checks" match="text()"/>

    <xd:doc>
        <xd:short>Verify paired punctuation marks match.</xd:short>
        <xd:detail>
            <p>Verify paired punctuation marks, such as parenthesis match and are not wrongly nested. This assumes that the 
            right single quote character (&rsquo;) is not being used for the apostrophe (hint: temporarily change those to
            something else). The paired punctuation marks supported are [], (), {}, &lsquo;&rsquo;, and &ldquo;&rdquo;.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template name="match-punctuation-pairs">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="expect" select="''" as="xs:string"/>

        <!-- Remove anything not a pairing punctionation mark -->
        <xsl:variable name="pairs" select="replace($string, '[^\[\](){}&lsquo;&rsquo;&rdquo;&ldquo;]', '')"/>

        <!-- Now the $pairs should start with what we expect: -->
        <xsl:if test="substring($pairs, 1, string-length($expect)) != $expect">
            <xsl:message terminate="no"><xsl:value-of select="f:line-number(.)"/> Paragraph does not start with <xsl:value-of select="$expect"/></xsl:message>
        </xsl:if>

        <!--
        <xsl:message terminate="no">Checking string: <xsl:value-of select="$string"/> </xsl:message>
        <xsl:message terminate="no">Checking pairs:  <xsl:value-of select="$pairs"/> </xsl:message>
        -->

        <xsl:variable name="head" select="if (string-length($string) &lt; 40) then $string else concat(substring($string, 1, 37), '...')"/>

        <xsl:variable name="unclosed" select="f:unclosed-pairs($pairs, '')"/>
        <xsl:choose>
            <xsl:when test="substring($unclosed, 1, 10) = 'unexpected'">
                <xsl:message terminate="no"><xsl:value-of select="f:line-number(.)"/> Paragraph [<xsl:value-of select="$head"/>] contains <xsl:value-of select="$unclosed"/></xsl:message>
            </xsl:when>
            <xsl:when test="$unclosed != ''">
                <xsl:message terminate="no"><xsl:value-of select="f:line-number(.)"/> Paragraph [<xsl:value-of select="$head"/>] contains unclosed punctuation: <xsl:value-of select="$unclosed"/></xsl:message>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:variable name="opener" select="'(', '[', '{', '&lsquo;', '&ldquo;'"/>
    <xsl:variable name="closer" select="')', ']', '}', '&rsquo;', '&rdquo;'"/>

    <xd:doc>
        <xd:short>Find unclosed pairs of paired punctuation marks.</xd:short>
        <xd:detail>
            <p>Find unclosed pairs of paired punctuation marks in a string of punctuation marks using recursive calls. 
            This pushes open marks on a stack, and pops them when the closing mark comes by.
            When an unexpected closing mark is encountered, we return an error; when the string is fully consumed,
            the remainder of the stack is returned. Normally, this is expected to be empty.</p>
        </xd:detail>
    </xd:doc>

    <xsl:function name="f:unclosed-pairs">
        <xsl:param name="pairs" as="xs:string"/>
        <xsl:param name="stack" as="xs:string"/>

        <xsl:variable name="head" select="substring($pairs, 1, 1)"/>
        <xsl:variable name="tail" select="substring($pairs, 2)"/>
        <xsl:variable name="expect" select="translate(substring($stack, 1, 1),'[({&lsquo;&ldquo;', '])}&rsquo;&rdquo;')"/>

        <!--
        <xsl:message terminate="no">Checking mark:   [<xsl:value-of select="$head"/>] : [<xsl:value-of select="$tail"/>]  (stack [<xsl:value-of select="$stack"/>], expect [<xsl:value-of select="$expect"/>]) </xsl:message>
        -->

        <xsl:sequence select="if (not($head))
                                then $stack
                                else if ($head = $opener)
                                    then f:unclosed-pairs($tail, concat($head, $stack))
                                    else if ($head = $expect)
                                        then f:unclosed-pairs($tail, substring($stack, 2))
                                        else concat('unexpected closer: ', $head)"/>
    </xsl:function>


    <!-- Get function for line numbers to work. See http://www.xmlplease.com/linenumber, but fix some issues here -->

    <xsl:function name="f:line-number" as="xs:string*">
        <xsl:param name="node" as="node()"/>
        <xsl:if test="$node/@__pos">
            <xsl:variable name="line" select="substring-before($node/@__pos, ':')"/>
            <xsl:variable name="column" select="substring-after($node/@__pos, ':')"/>

            <xsl:text>line </xsl:text><xsl:value-of select="$line"/> column <xsl:value-of select="$column"/>
        </xsl:if>
    </xsl:function>

    <!--

    <xsl:function name="f:log-issue">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="issue" as="xs:string"/>

    </xsl:function>

    -->

</xsl:stylesheet>