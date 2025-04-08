proc import datafile = "/home/u63980094/sample10k_post.csv"
	out=sample
	dbms=csv
	replace;
	getnames=yes;
run;

data work.sample;
set sample;
if win = 0 then wl = lose;
else if lose = 0 then wl = win;
else wl = win/lose;
IF DEATHS = 0 THEN KDA = KILLS+ASSISTS;
ELSE kda = (kills+assists)/deaths;
SELECT (tier);
    	WHEN ("IRON") tier_cat = 1;
    	WHEN ("BRONZE") tier_cat = 2;
    	WHEN ("SILVER") tier_cat =3;
    	WHEN ("GOLD") tier_cat = 4;
    	WHEN ("PLATINUM") tier_cat = 5;
    	WHEN ("DIAMOND") tier_cat = 6;
    	WHEN ("EMERALD") tier_cat = 7;
    	WHEN ("MASTER") tier_cat = 8;
    	WHEN ("GRANDMAS") tier_cat = 9;
    	WHEN ("CHALLENGER") tier_cat =10;
    	OTHERWISE;
    END;
run;

proc univariate data=work.sample noprint;
var kda wl lp;
output out=percentiles pctlpts=5 95 pctlpre=var1_ var2_;
data mydata_with_percentiles;
if _n_ = 1 then set percentiles;
set work.sample;
data trimmed_data;
set mydata_with_percentiles;
if kda > var1_5 and kda < var1_95 and wl > var2_5 and wl < var2_95;
data sample595;
set trimmed_data;
drop var1_5 var1_95 var2_5 var2_95;
    
 
proc univariate data=work.sample595 plots normal;
var kda;
run;

proc freq data=work.sample;
tables position_name tier_cat;
run;

PROC MEANS data=work.sample n mean median min max std var nmiss;
var kda wl avg_op;
RUN;

PROC CORR data=work.sample595 pearson plots(maxpoints=100000)=matrix(histogram);
var kda wl avg_op;
RUN;

PROC ANOVA data=work.sample plots(maxpoints=10000);
class position_name;
model avg_op = position_name;
MEANS position_name / TUKEY;

*proc reg with all continuous;
PROC REG data = work.sample595 plots(maxpoints=100000);
  model avg_op = kda wl win_rate/ stb clb;
  output out=stdres p= predict student=resids;
RUN;
QUIT;
*Norm of resid;
proc univariate data=stdres plots normal;
var resids;
run;
*proc reg with the most influential (KDA);
PROC REG data = work.sample595 plots(maxpoints=100000);
  model avg_op = kda / stb clb;
  output out=stdres p= predict student=resids;
RUN;
QUIT;
*Norm of resids;
proc univariate data=stdres plots normal;
var resids;
run;

proc glm data=work.sample595 plots(maxpoints=1000000);
class tier position_name;
model avg_op = kda wl pick_rate ban_rate win_rate  tier position_name;
lsmeans tier position_name /pdiff=all adjust=tukey cl;
run;
quit;

*narrowed proc glm;
proc glm data=work.sample595 plots(maxpoints=1000000);
class position_name;
model avg_op = wl position_name / solution;
lsmeans position_name /pdiff=all adjust=tukey cl;
output out=residual_output r=residual p=predicted_value 
	student=student_resid h=leverage cookd=cook_distance;
run;
quit;
*Residual Analysis;
proc univariate data=residual_output plots normal;
var residual;
run;

*proc logistic for lane;
proc logistic data=work.sample595 plots(maxpoints=100000);
class position_name;
model position_name = avg_op pick_rate win_rate ban_rate;