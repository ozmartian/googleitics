<cfsetting enablecfoutputonly="true" />

<cfset username = "YOUR_GOOGLE_USERNAME" />
<cfset password = "YOUR_GOOGLE_PASSWORD" />
<cfset profileID = "YOUR_WEBSITE_PROFILE_ID" />
<cfset mapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY" />

<!--- array of 1 or more profileIDs for AnnotatedTimeLine example --->
<!--- e.g. ["1234465","3244545","565464"] --->
<cfset aProfileIDs = [  ] />

<cfset startDate = "2009-04-01" />
<cfset endDate = lsDateFormat(now(), "yyyy-mm-dd") />

<cfif username neq "YOUR_GOOGLE_USERNAME" AND password neq "YOUR_GOOGLE_PASSWORD" AND profileID neq "YOUR_WEBSITE_PROFILE_ID">
	<cfset oGA = createObject("component", "googleitics").init(username, password) />

	<cfset qMetrics = oGA.getMetrics(profileID, startDate, endDate) />
	<cfset qBrowsers = oGA.getMetrics(profileID=profileID, startDate=startDate, endDate=endDate, dimensions="ga:browser", metrics="ga:pageviews", sort="-ga:pageviews,ga:browser") />
	<cfset qWeek = oGA.getMetrics(profileID=profileID, startDate=lsDateFormat(now()-6, "yyyy-mm-dd"), endDate=endDate, dimensions="ga:date", metrics="ga:visits,ga:newVisits", sort="ga:date") />
	<cfset qCities = oGA.getMetrics(profileID=profileID, startDate=startDate, endDate=endDate, dimensions="ga:city", metrics="ga:visits", sort="-ga:visits,ga:city") />
	<cfset qCountries = oGA.getMetrics(profileID=profileID, startDate=startDate, endDate=endDate, dimensions="ga:country", metrics="ga:visits", sort="-ga:visits,ga:country") />

	<!--- draw AnnotatedTimeLine --->
	<cfif NOT arrayIsEmpty(aProfileIDs)>
		<cfset oGA.drawTimeLine(aProfileIDs=aProfileIDs, startDate=lsDateFormat(dateAdd("m", -2, now()), "yyyy-mm-dd"), endDate=endDate, element="chart_timeline") />
	</cfif>

	<!--- draw GeoMap --->
	<cfif mapsAPIKey neq "YOUR_GOOGLE_MAPS_API_KEY">
		<cfset oGA.drawGeoMap(qMetrics=qCountries, element="chart_geomap", apiKey=mapsAPIKey) />
	</cfif>

	<!--- draw miscellaneous charts --->
	<cfset oGA.drawChart(qMetrics=qWeek, element="chart_week", type="AreaChart", title="Visits for Past Week", legend="bottom") />
	<cfset oGA.drawChart(qMetrics=qBrowsers, element="chart_browser", type="PieChart", title="Pageviews by Top 10 Browsers", legend="right", width=450, limit=10) />
</cfif>

<cfoutput><html>
	<head>
		<title>googleitics Examples</title>
		<link rel="shortcut icon" href="http://google.com/favicon.ico" />
		<style type="text/css">
		.error { color:maroon; font-weight:bold; font-size:16px; padding:6px; border:1px solid maroon; }
		a { text-decoration:none; font-weight:bold; }
		a:hover { text-decoration:underline; }
		</style>
	</head>
	<body>
		<div align="center">
			<h2>googleitics Examples</h2>
			<div align="center" style="font-size:11px;border:1px solid black;width:500px;padding:10px;">
				See the <a href="http://code.google.com/apis/analytics/docs/gdata/gdataReferenceDimensionsMetrics.html" target="_blank" title="Google Analytics API Reference">Google Analytics API Reference</a>
				for a full list of dimension and metric combinations.
				<br/><br/>
				<a href="http://code.google.com/apis/maps/signup.html" target="_blank" title="Sign up for the Google Maps API">Sign up for the Google Maps API</a> to generate your API Key. 
				<br/><br/>
				See the charts section in the <a href="http://code.google.com/apis/visualization/documentation/gallery.html" target="_black" title="Google Visualisation API Reference">Google Visualisation API Reference</a>
				for a full list of chart types.
			</div>
			<br/>
			<cfif username neq "YOUR_GOOGLE_USERNAME" AND password neq "YOUR_GOOGLE_PASSWORD" AND profileID neq "YOUR_WEBSITE_PROFILE_ID">
			<table border="0" cellpadding="10" cellspacing="0">
				<tr valign="top" align="center">
					<td colspan="2">
						<cfif NOT arrayIsEmpty(aProfileIDs)>
						<h4>Visits for Past 3 Months (Annotated Time Line)</h4>
						<div id="chart_timeline" style="width:700px;height:240px;"></div>
						<cfelse>
						<span class="error">Please provide an array of profileIDs to see the AnnotatedTimeLine</span>
						</cfif>
					</td>
				</tr>
				<tr valign="top" align="center">
					<td colspan="2">
						<cfif mapsAPIKey neq "YOUR_GOOGLE_MAPS_API_KEY">
						<h4>Visits by Country GeoMap</h4>
						<div id="chart_geomap" style="border:1px solid black;width:556px;"></div>
						<cfelse>
						<span class="error">Please provide your <a href="http://code.google.com/apis/maps/signup.html" target="_blank" title="Google Maps API Key">Google Maps API Key</a> to see the GeoMap</span>
						</cfif>
					</td>
				</tr>
				<tr valign="top" align="center">
					<td><div id="chart_week" align="center" style="padding:10px;"></div></td>
					<td><div id="chart_browser" align="center" style="padding:10px;"></div></td>
				</tr>
				<tr valign="top">
					<td colspan="2"align="center"><cfdump var="#qMetrics#" label="[#oGA.stcProfiles[profileID].title#] General Metrics" /></td>
				</tr>
				<tr valign="top" align="center">
					<!--- <td><cfdump var="#stcProfiles#" label="Google Analytics Profiles" /></td> --->
					<td align="right">
						<cfdump var="#qWeek#" label="[#oGA.stcProfiles[profileID].title#] Visits for Past Week" />
						<br/>
						<cfdump var="#qBrowsers#" label="[#oGa.stcProfiles[profileID].title#] Pageviews by Browser" />
					</td>
					<td align="left"><cfdump var="#qCities#" label="[#oGA.stcProfiles[profileID].title#] Visits by City"></td>
				</tr>
			</table>
			<cfelse>
			<div>
				<p>
					<span class="error">Please provide your Google username, password and a Google Analytics website profileID</span>
				</p>
			</div>
			</cfif>
		</div>
	</body>
</html></cfoutput>


<cfsetting enablecfoutputonly="false" />