googleitics
===========

**What is this then?** A ColdFusion component wrapper for the Google Analytics API...

##Project Summary

googleitics is a CFC providing charts and metrics for your website profiles at Google Analytics through API wrapper methods.

All valid metrics can be retrieved with the option to group them by a dimension (see API Reference link below) e.g. browser, city, date etc. At this stage, only one dimension can be specified but this will change in future releases.

The Google Visualisation API is used to provide interactive charts via drawChart() and two examples are included in the test script.

This serves as a good jump start to pulling down Google Analytics data through the recently released API. An example script is included to assist you in using the CFC.

To see a list of all currently available metrics in Google Analytics API, go here:

http://code.google.com/apis/analytics/docs/gdata/gdataReferenceDimensionsMetrics.html

Feel free to contact me if you have a bug to report, would like features added or need help getting this to work.

##Updates / Notes

** minor bug fix applied to drawTimeLine() to resolve issues when website profile title's contain characters that cannot be used as query column headings.. this fix is only available via the Subversion trunk **

** UPDATE: v3.51 adds a few minor ColdFusion 9 improvements **

** UPDATE: v3.5 includes new drawTimeLine() method for AnnotatedTimeLine chart of dimension (e.g. visits) against multiple website profiles (e.g to see visits compared across multiple sites). Minor improvements made in other areas. **

** UPDATE: v3.0 includes AnnotatedTimeLine visualisation support and a fix for getProfiles() due to a recent Google API change **

** UPDATE: v2.5 includes GeoMap visualisation (requires a Google Maps API Key) **

** UPDATE: v2.0 includes Google Visualisation API charts **

##Requirements

- ColdFusion 7+ or Railo 3+ (untested on BlueDragon but it "should" work)

- Google Analytics Account + Website Profile

- Google Maps API Key (for GeoMap Visualiation)

* see test script (index.cfm) for info & links to what is required AND ensure you replace the variables up top with your own Google account, website and Maps API Key values *
