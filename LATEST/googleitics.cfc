<!---

	googleitics v3.51

	Copyright 2009 Pete Alexandrou [pete@iclp.com.au]
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

--->

<cfcomponent displayname="googleitics" hint="I perform various Google Analytics API calls to retrieve website metrics." output="false">

	<cfset this.version = "3.51" />
	<cfset this.loginURL = "https://www.google.com/accounts/ClientLogin" />
	<cfset this.accountsURL = "https://www.google.com/analytics/feeds/accounts/default" />
	<cfset this.metricsURL = "https://www.google.com/analytics/feeds/data?" />
	<cfset this.lMetrics = "ga:bounces,ga:entrances,ga:exits,ga:newVisits,ga:pageviews,ga:timeOnPage,ga:timeOnSite,ga:visitors,ga:visits" />
	<cfset this.stcProfiles = structNew() />

	<!------------------------------------------------------[ init() ]------------------------------------------------------>

	<cffunction name="init" access="public" returntype="googleitics" output="false" hint="I am the googleitics constructor.">
		<cfargument name="username" type="string" required="true" />
		<cfargument name="password" type="string" required="true" />
		<cfset variables.instance = structNew() />
		<cfset variables.instance.username = arguments.username />
		<cfset variables.instance.loginToken = _login(username=arguments.username, password=arguments.password) />
		<cfset this.stcProfiles = this.getProfiles() />
		<cfset variables.instance.mapsAPI = false />
		<cfset variables.instance.jsAPI = false />
		<cfreturn this />
	</cffunction>

	<!------------------------------------------------------[ getMetrics() ]------------------------------------------------------>

	<cffunction name="getMetrics" access="public" returntype="query" output="false" hint="I return a query recordset of Google Analytics dimensions & metrics for a given website profile.">
		<cfargument name="profileID" type="string" required="true" hint="I am a valid Google Analytics website profile identifier." />
		<cfargument name="startDate" type="string" required="true" hint="I am the start date for feed data (yyyy-mm-dd)." />
		<cfargument name="endDate" type="string" required="true" hint="I am the end date for feed data (yyyy-mm-dd)." />
		<cfargument name="dimensions" type="string" required="false" default="" hint="I am a list of Google Analytics dimension elements." />
		<cfargument name="metrics" type="string" required="false" default="#this.lMetrics#" hint="I am a list of Google Analytics metric elements." />
		<cfargument name="sort" type="string" required="false" default="" hint="I am a list dimension or metric elements to sort results by." />
		<cfset var qMetrics = queryNew("") />
		<cfset var xmlMetrics = "" />
		<cfset var aDimensions = arrayNew(1) />
		<cfset var aMetrics = arrayNew(1) />
		<cfset var stcMetrics = structNew() />
		<cfset var aResults = arrayNew(1) />
		<cfset var lNames = arrayNew(1) />
		<cfset var aValues = arrayNew(1) />
		<cfset var counter = 0 />
		<cfset var i = 0 />
		<cfset var gaURL = this.metricsURL & "ids=ga:" & arguments.profileID & "&dimensions=" & arguments.dimensions & "&metrics=" & arguments.metrics & "&sort=" & arguments.sort & "&start-date=" & arguments.startDate & "&end-date=" & arguments.endDate />
		<cfset xmlMetrics = callAPI(gaURL, variables.instance.loginToken) />
		<cftry>
			<cfset xmlMetrics = xmlParse(reReplaceNoCase(reReplaceNoCase(xmlMetrics, "(</?)(\w+:)", "\1", "ALL"), "<feed[^>]*>", "<feed>")) />
			<cfif len(arguments.dimensions)>
				<cfset aResults = xmlSearch(xmlMetrics, "//entry/") />
				<cfloop from="1" to="#arrayLen(aResults)#" index="counter">
					<cfif aResults[counter].dimension.XmlAttributes["name"] eq "ga:date">
						<cfset aDimensions[counter] = "#right(aResults[counter].dimension.XmlAttributes['value'], 2)#/#mid(aResults[counter].dimension.XmlAttributes['value'], 5, 2)#/#left(aResults[counter].dimension.XmlAttributes['value'], 4)#" />
					<cfelse>
						<cfset aDimensions[counter] = aResults[counter].dimension.XmlAttributes["value"] />
					</cfif>
					<cfset aValues = xmlSearch(aResults[counter], "metric") />
					<cfloop from="1" to="#arrayLen(aValues)#" index="i">
						<cfset stcMetrics[replaceNoCase(aValues[i].XmlAttributes["name"], "ga:", "")] = aValues[i].XmlAttributes["value"] />
					</cfloop>
					<cfset aMetrics[counter] = duplicate(stcMetrics) />
				</cfloop>
				<cfset queryAddColumn(qMetrics, replaceNoCase(aResults[1].dimension.XmlAttributes["name"], "ga:", ""), aDimensions) />
				<cfset lNames = structKeyList(aMetrics[1]) />
				<cfloop from="1" to="#listLen(lNames)#" index="counter">
					<cfloop from="1" to="#arrayLen(aMetrics)#" index="i">
						<cfset aValues[i] = structFind(aMetrics[i], listGetAt(lNames, counter)) />
					</cfloop>
					<cfset queryAddColumn(qMetrics, listGetAt(lNames, counter), aValues) />
				</cfloop>
			<cfelse>
				<cfset aResults = xmlSearch(xmlMetrics, "//aggregates/") />
				<cfset aResults = aResults[1].XmlChildren />
				<cfloop from="1" to="#arrayLen(aResults)#" index="counter">
					<cfset queryAddColumn(qMetrics, replaceNoCase(aResults[counter].XmlAttributes["name"], "ga:", ""), listToArray(aResults[counter].XmlAttributes["value"])) />
				</cfloop>
				<cfset queryAddColumn(qMetrics, "startDate", listToArray(arguments.startDate)) />
				<cfset queryAddColumn(qMetrics, "endDate", listToArray(arguments.endDate)) />
			</cfif>
			<cfcatch type ="any">
				<cfoutput>
					<cfdump var="#xmlMetrics#" label="API Response" />
					<br/>
					<cfdump var="#aResults#" label="Processed XML" />
					<br/>
					<cfdump var="#qMetrics#" label="Return Query" />
					<br/>
					<cfdump var="#cfcatch#" label="Exception" />
				</cfoutput>
				<cfabort />
			</cfcatch>
		</cftry>
		<cfreturn qMetrics />
	</cffunction>

	<!------------------------------------------------------[ getProfiles() ]------------------------------------------------------>

	<cffunction name="getProfiles" access="public" returntype="struct" output="false" hint="I return all Google Analytics profiles associated with the authenticated account.">
		<cfset var stcProfiles = structNew() />
		<cfset var aEntries = arrayNew(1) />
		<cfset var stcEntry = structNew() />
		<cfset var num = 0 />
		<cfset var i = 0 />
		<cfset var accountXML = callAPI(this.accountsURL, variables.instance.loginToken) />
		<cfset accountXML = reReplaceNoCase(reReplaceNoCase(accountXML, "(</?)(\w+:)", "\1", "ALL"), "<feed[^>]*>", "<feed>") />
		<cfset aEntries = xmlSearch(accountXML, "//entry/") />
		<cfloop from="1" to="#arrayLen(aEntries)#" index="num">
			<cfset stcEntry = structNew() />
			<cfset stcEntry.id = aEntries[num].id.XmlText />
			<cfset stcEntry.title = aEntries[num].title.XmlText />
			<cfset stcEntry.tableId = aEntries[num].tableId.XmlText />
			<cfloop from="1" to="#arrayLen(aEntries[num].property)#" index="i">
				<cfswitch expression='#aEntries[num].property[i].XmlAttributes["name"]#'>
					<cfcase value="ga:accountId">
						<cfset stcEntry.accountId = aEntries[num].property[i].XmlAttributes["value"] />
					</cfcase>
					<cfcase value="ga:accountName">
						<cfset stcEntry.accountName = aEntries[num].property[i].XmlAttributes["value"] />
					</cfcase>
					<cfcase value="ga:profileId">
						<cfset stcEntry.profileId = aEntries[num].property[i].XmlAttributes["value"] />
					</cfcase>
					<cfcase value="ga:webPropertyId">
						<cfset stcEntry.webPropertyId = aEntries[num].property[i].XmlAttributes["value"] />
					</cfcase>
				</cfswitch>
			</cfloop>
			<cfset stcProfiles[stcEntry.profileID] = duplicate(stcEntry) />
		</cfloop>
		<cfreturn stcProfiles />
	</cffunction>

	<!------------------------------------------------------[ callAPI() ]------------------------------------------------------>

	<cffunction name="callAPI" access="public" returntype="string" output="false" hint="I make a call to the Google Analytics API via HTTP.">
		<cfargument name="gaURL" type="string" required="true" />
		<cfargument name="authToken" type="string" required="true" />
		<cfset var responseOutput = "" />
		<cfset var authSubToken = "GoogleLogin auth=" & arguments.authToken />
		<cfhttp url="#arguments.gaURL#" method="get" resolveurl="true">
			<cfhttpparam name="Authorization" type="header" value="#authSubToken#" />
		</cfhttp>
		<cfif isDefined("url.api")>
			<cfdump var="#cfhttp#" label="CFHTTP" />
			<cfabort />
		</cfif>
		<cfif cfhttp.statusCode eq "200 OK">
			<cfset responseOutput = cfhttp.fileContent />
		<cfelse>
			<cfsavecontent variable="responseOutput">
				<cfdump var="#cfhttp#" label="CFHTTP Error" />
			</cfsavecontent>
		</cfif>
		<cfreturn responseOutput />
	</cffunction>

	<!------------------------------------------------------[ drawChart() ]------------------------------------------------------>

	<cffunction name="drawChart" access="public" returntype="void" output="false" hint="I generate JavaScript code to render an interactive chart using the Google Visualization API.">
		<cfargument name="qMetrics" type="query" required="true" />
		<cfargument name="element" type="string" required="true"  />
		<cfargument name="type" type="string" required="false" default="ColumnChart" />
		<cfargument name="width" type="numeric" required="false" default=400 />
		<cfargument name="height" type="numeric" required="false" default=300 />
		<cfargument name="title" type="string" required="false" default="" />
		<cfargument name="is3D" type="boolean" required="false" default="true" />
		<cfargument name="axisFontSize" type="numeric" required="false" default="10" />
		<cfargument name="legendFontSize" type="numeric" required="false" default="10" />
		<cfargument name="legend" type="string" required="false" default="right" />
		<cfargument name="limit" type="numeric" required="false" default="0" />
		<cfset var qData = arguments.qMetrics />
		<cfset var jScript = "" />
		<cfset var lColumnNames = arguments.qMetrics.columnList />
		<cfset var heading = "" />
		<cfset var value = "" />
		<cfset var c = 1 />
		<cfif arguments.limit gt 0>
			<cfquery name="qData" dbtype="query" maxrows="#arguments.limit#">
			SELECT * FROM qData
			</cfquery>
		</cfif>
		<cfsavecontent variable="jScript">
			<cfoutput>
			<script type="text/javascript">
			google.load('visualization', '1', { packages:['#lCase(arguments.type)#'] });
			google.setOnLoadCallback(drawChart);
			function drawChart() {
				var data = new google.visualization.DataTable();
				<cfset c = 1 />
				<cfloop list="#lColumnNames#" index="heading">
					<cfset value = evaluate("qData.#heading#") />
					<cfset heading = replaceNoCase(heading, "S_", "", "ALL") />
					<cfif listLen(value, "/") eq 3>
						data.addColumn('date', 'Date');
					<cfelseif isNumeric(value) AND c gt 1>
						data.addColumn('number', '#heading#');
					<cfelse>
						data.addColumn('string', '#heading#');
					</cfif>
					<cfset c = c + 1 />
				</cfloop>
				data.addRows(#qData.recordCount#);
				<cfloop query="qData">
					<cfloop from="1" to="#listLen(lColumnNames)#" index="c">
						<cfset value = evaluate("qData.#listGetAt(lColumnNames, c)#") />
						<cfif listLen(value, "/") eq 3>
							data.setValue(#qData.currentRow-1#, #c-1#, new Date(#listLast(value, "/")#, #listGetAt(value, 2, "/")-1#, #listFirst(value, "/")#));
						<cfelseif isNumeric(value) AND c gt 1>
							data.setValue(#qData.currentRow-1#, #c-1#, #value#);
						<cfelse>
							data.setValue(#qData.currentRow-1#, #c-1#, '#value#');
						</cfif>
					</cfloop>
				</cfloop>
				var chart = new google.visualization.#arguments.type#(document.getElementById('#arguments.element#'));
				<cfif arguments.type eq "AnnotatedTimeLine">
				chart.draw(data, { displayAnnotations: true });
				<cfelse>
				chart.draw(data, { width:#arguments.width#, height:#arguments.height#, is3D:#arguments.is3D#, title:'#arguments.title#', axisFontSize:#arguments.axisFontSize#, legendFontSize:#arguments.legendFontSize#, legend:'#arguments.legend#' });
				</cfif>
			}
			</script>
			</cfoutput>
		</cfsavecontent>
		<cfif NOT variables.instance.jsAPI>
			<cfset jScript = '<script type="text/javascript" src="http://www.google.com/jsapi"></script>#chr(13)##chr(10)#' & jScript />
			<cfset variables.instance.jsAPI = true />
		</cfif>
		<cfhtmlhead text="#jScript#" />
	</cffunction>

	<!------------------------------------------------------[ drawGeoMap() ]------------------------------------------------------>

	<cffunction name="drawGeoMap" access="public" returntype="void" output="false">
		<cfargument name="qMetrics" type="query" required="true" />
		<cfargument name="apiKey" type="string" required="true" />
		<cfargument name="element" type="string" required="true"  />
		<cfset var qData = arguments.qMetrics />
		<cfset var jScript = "" />
		<cfset var lColumnNames = qData.columnList />
		<cfset var heading = "" />
		<cfset var value = "" />
		<cfset var c = 1 />
		<cfsavecontent variable="jScript">
			<cfoutput>
			<script type="text/javascript">
			google.load('visualization', '1', { packages:['geomap'] });
			google.setOnLoadCallback(drawMap);
			function drawMap() {
				var data = new google.visualization.DataTable();
				<cfset c = 1 />
				<cfloop list="#lColumnNames#" index="heading">
					<cfset value = evaluate("qData.#heading#") />
					<cfif isNumeric(value) AND c gt 1>
						data.addColumn('number', '#heading#');
					<cfelse>
						data.addColumn('string', '#heading#');
					</cfif>
					<cfset c = c + 1 />
				</cfloop>
				data.addRows(#qData.recordCount#);
				<cfloop query="qData">
					<cfloop from="1" to="#listLen(lColumnNames)#" index="c">
						<cfset value = evaluate("qData.#listGetAt(lColumnNames, c)#") />
						<cfif isNumeric(value) AND c gt 1>
							data.setValue(#qData.currentRow-1#, #c-1#, #value#);
						<cfelse>
							data.setValue(#qData.currentRow-1#, #c-1#, '#value#');
						</cfif>
					</cfloop>
				</cfloop>
				var geomap = new google.visualization.GeoMap(document.getElementById('#arguments.element#'));
				geomap.draw(data, { region:'world', dataMode:'markers' });
			}
			</script>
			</cfoutput>
		</cfsavecontent>
		<cfif NOT variables.instance.mapsAPI>
			<cfset jScript = '<script src="http://maps.google.com/maps?file=api&v=2&sensor=false&key=#arguments.apiKey#" type="text/javascript"></script>#chr(13)##chr(10)#' & jScript />
		</cfif>
		<cfif NOT variables.instance.jsAPI>
			<cfset jScript = '<script type="text/javascript" src="http://www.google.com/jsapi"></script>#chr(13)##chr(10)#' & jScript />
			<cfset variables.instance.jsAPI = true />
		</cfif>
		<cfhtmlhead text="#jScript#" />
	</cffunction>

	<!------------------------------------------------------[ _login() ]------------------------------------------------------>

	<cffunction name="drawTimeLine" access="public" returntype="void" output="false">
		<cfargument name="aProfileIDs" type="array" required="true" />
		<cfargument name="startDate" type="date" required="true" />
		<cfargument name="endDate" type="date" required="true" />
		<cfargument name="element" type="string" required="true"  />
		<cfargument name="metric" type="string" required="false" default="ga:visits" />
		<cfset var qMetrics = queryNew("x") />
		<cfset var qData = queryNew("x") />
		<cfset var counter = 1 />
		<cfset var profileID = "" />
		<cfloop array="#arguments.aProfileIDs#" index="profileID">
			<cfset qMetrics = this.getMetrics(profileID=profileID, startDate=arguments.startDate, endDate=arguments.endDate, dimensions="ga:date", metrics=arguments.metric, sort="ga:date") />
			<cfif counter eq 1>
				<cfset queryAddColumn(qData, "Date", "varchar", listToArray(valueList(qMetrics.date))) />
			</cfif>
			<cfset queryAddColumn(qData, "S_" & replace(listFirst(this.stcProfiles[profileID].accountName, " "), ".", "", "ALL"), "integer", listToArray(valueList(qMetrics.visits))) />
			<cfset counter++ />
		</cfloop>
		<cfset this.drawChart(qMetrics=qData, element=arguments.element, type="AnnotatedTimeLine") />
	</cffunction>

	<!------------------------------------------------------[ _login() ]------------------------------------------------------>

	<cffunction name="_login" access="private" returntype="string" output="false" hint="I establish an authenticated session w/ Google Analytics API.">
		<cfargument name="username" type="string" required="true" />
		<cfargument name="password" type="string"required="true" />
	    <cfset var loginToken = "" />
	    <cfhttp url="#this.loginURL#" method="post" resolveurl="true">
	        <cfhttpparam name="accountType" type="url" value="GOOGLE" />
	        <cfhttpparam name="Email" type="url" value="#arguments.username#" />
	        <cfhttpparam name="Passwd" type="url" value="#arguments.password#" />
	        <cfhttpparam name="service" type="url" value="analytics" />
	        <cfhttpparam name="source" type="url" value="ColdFusion-googleitics-3.51" />
	    </cfhttp>
		<cfif NOT findNoCase("Auth=", cfhttp.fileContent)>
			<cfset loginToken = "Authorization Failed" />
		<cfelse>
			<cfset loginToken = mid(cfhttp.fileContent, findNoCase("Auth=", cfhttp.fileContent) + (len("Auth=")), len(cfhttp.fileContent)) />
		</cfif>
	    <cfreturn loginToken />
	</cffunction>

</cfcomponent>