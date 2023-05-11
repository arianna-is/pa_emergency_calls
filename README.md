# pa_emergency_calls
Analysis of Montgomery County, PA 911 Call Data

This project involved both data cleaning and manipulation using SQL (MySQL) and a visualization using Tableau Public.

The SQL portion of this project involved cleaning data by adjusting column data types, eliminating key words from column names, separating one column into two separate columns, parsing information from a longer and generalized info column into a more specific and useable column, and adjusting several data points that were entered with erroneous location data.

I then did some data exploration in SQL to see what the dataset looked like, and determine what visualizations would be the most informative.

In my visualizations, I chose to highlight information that would be helpful to a city in determining the amount of demand for different resources and how that demand varies over different time periods. I highlighted the number of calls received for EMS, fire, and traffic resources, as well as the frequency of different types of calls for each of these resources. I also included a ranking of the top 5 busies EMS and fire stations as well as the average number of calls they run over a weeklong period. 

Tableau Visualization:
https://public.tableau.com/views/MontgomeryCountyEmergencyCalls/Dashboard?:language=en-US&publish=yes&:display_count=n&:origin=viz_share_link


This analysis and visualization was based on data taken from Kaggle at the following link, and represents data from December 2015 through July 2020:
https://www.kaggle.com/datasets/mchirico/montcoalert
