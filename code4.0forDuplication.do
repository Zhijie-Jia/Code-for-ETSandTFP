use   dataprocssing.dta,clear
global X1 "lnrgdppC gdp2ndp lnrFDIpC r_unemp lnrfiscaledupG lnrfiscalscipG" 

global X2 "d_lnrgdppC d_gdp2ndp d_lnrFDIpC d_r_unemp d_lnrfiscaledupG d_lnrfiscalscipG" 



xtset citycode year


cap drop _merge
	merge 1:1 citycode year using TFPreultsprocssing.dta
	//每个城市第一次出现的效率为1
	sort citycode year
	by citycode: gen z=_n
	by citycode: replace A_TFPCH=1 if z==1
	by citycode: replace TFPCH=1 if z==1
	drop z

	//增长率
	gen TFP = TFPCH

/* 效率测算2--------------------------------------------*/
// xtset citycode year
// xtbalance, range(2005 2016) miss( rcapital emp power rgdp CO2) //nddfeff要求平衡面板  
// // nddfeff rcapital emp power = rgdp : CO2, dmu(citycode) time(year) seq sav(TFPreults-NDDF-GTFP,replace) vrs maxiter(160000) 
// merge 1:1 citycode year using TFPreults-NDDF-GTFP.dta
// drop _merge
// gen TFP= 1-Dval
// gen CO2EFF=1-B_CO2	
//	
// // //// 用于稳健性
// // malmq2 rcapital emp = rgdp, global saving(TFPreults-TFP-I.dta,replace) ort(i) rd
// // malmq2 rcapital emp = rgdp, seq saving(TFPreults-TFP-seq.dta,replace) ort(o) rd
// //
// timer on   1
// sftfe lnrgdp lnrcapital lnemp, est(mmsle) dist(hn) seed(10101)
// timer off  1
// timer list 1
// predict  TE, jlms	
// bys citycode (year): gen TFP=d.TE
// replace TFP= 0 if TFP==.	
//	
// //缩尾+数据清洗2-----------------------------------------
// // winsor2 TFPCH, replace cuts(1 99) trim
// // drop if TFPCH==.


//PSM----------------------------------------------------

bysort citycode: egen treatment=mean(D_ETS)
replace treatment=1 if treatment!=0

save  dataprocssing.dta, replace
//2008
use  dataprocssing.dta, clear
keep  if year==2008                                                      //时间

set   seed 10101
gen   ranorder=runiform()
sort  ranorder

// psmatch2 treatment $X1 , outcome(TFP) n(4) ate ties logit               //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.1)  ate               //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.25) ate                    //卡尺内进行k近邻匹配
psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.05) ate                //核匹配   
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
// psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配                 
// psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white))  
psgraph, bin (20)   graphregion(color(white)) 

keep  citycode _weight _support
rename _weight _weight2008           
rename _support _support2008
save  psm2008.dta, replace

//2009
use  dataprocssing.dta, clear
keep  if year==2009                                                      //时间

set   seed 10101
gen   ranorder=runiform()
sort  ranorder
//
// psmatch2 treatment $X1 , outcome(TFP) n(6) ate ties logit               //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.25)  ate               //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.15) ate                    //卡尺内进行k近邻匹配
psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.04)  ate               //核匹配
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
//psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配
// psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white))
psgraph, bin (20)  graphregion(color(white)) 

keep  citycode _weight _support
rename _weight _weight2009
rename _support _support2009
save  psm2009.dta, replace

//2010
use  dataprocssing.dta, clear
keep  if year==2010                                                       //时间

set   seed 10101
gen   ranorder=runiform()
sort  ranorder

// psmatch2 treatment $X1 , outcome(TFP) n(4) ate ties logit common               //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.1)  ate common              //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.25) ate common                   //卡尺内进行k近邻匹配
psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.02)  ate common                //核匹配
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
// psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配
// psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white)) 
psgraph, bin (20)  graphregion(color(white)) 

keep  citycode _weight _support
rename _weight _weight2010
rename _support _support2010
save  psm2010.dta, replace

//合并权重
use   dataprocssing.dta,clear
cap drop _merge
merge m:1 citycode using psm2008.dta
drop _merge
merge m:1 citycode using psm2009.dta
drop _merge
merge m:1 citycode using psm2010.dta
drop _merge
replace _weight2008=0 if _weight2008==.
replace _weight2009=0 if _weight2009==.
replace _weight2010=0 if _weight2010==.
gen _weight=(_weight2008 +_weight2009 +_weight2010)/3
// replace _weight=_weight*1000
// replace _weight=round(_weight)


//保存PSM合并的结果
keep if year<=2016 & year>=2005
gen 	_weightoriginal=_weight
gen 	_weight2	=	_weight
replace _weight 	=	1 if treatment==0
replace _weight2	=	1 if treatment==1
forvalues i=2008/2010 {
replace _weight 	=	_weight -1/3 	if (_support`i'==0 | _support`i'==.) & treatment==0
replace _weight2 	=	_weight2-1/3 	if (_support`i'==0 | _support`i'==.) & treatment==1
}

save dataprocessing3, replace


//模型检验-----------------------------------------------

//平行趋势检验
xtset citycode year
gen D_ETS0 =(D_ETS!=0)
by citycode (year): replace D_ETS0=0 if D_ETS-D_ETS[_n-1]!=1
gen D_ETS_06 = f6.D_ETS0
gen D_ETS_05 = f5.D_ETS0
gen D_ETS_04 = f4.D_ETS0
gen D_ETS_03 = f3.D_ETS0
gen D_ETS_02 = f2.D_ETS0
gen D_ETS_01 = f1.D_ETS0
replace D_ETS_01 =0 if D_ETS_01==.
replace D_ETS_02 =0 if D_ETS_02==. 
replace D_ETS_03 =0 if D_ETS_03==. 
replace D_ETS_04 =0 if D_ETS_04==.
replace D_ETS_05 =0 if D_ETS_05==.
replace D_ETS_06 =0 if D_ETS_06==.

gen D_ETS_1 = l1.D_ETS0
gen D_ETS_2 = l2.D_ETS0
gen D_ETS_3 = l3.D_ETS0
gen D_ETS_4 = l4.D_ETS0
replace D_ETS_1 =0 if D_ETS_1==. 
replace D_ETS_2 =0 if D_ETS_2==. 
replace D_ETS_3 =0 if D_ETS_3==. 
replace D_ETS_4 =0 if D_ETS_4==. 

gen D_ETSrest = D_ETS  -D_ETS_04 -D_ETS_03 -D_ETS_02 -D_ETS_01 -D_ETS0 -D_ETS_1 -D_ETS_2 -D_ETS_3 -D_ETS_4 
replace D_ETSrest =0 if D_ETSrest<=0

xtreg TFP D_ETS_05 D_ETS_04 D_ETS_03 D_ETS_02 D_ETS_01 D_ETS0 D_ETS_1 D_ETS_2 D_ETS_3 D_ETS_4 D_ETSrest $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
coefplot, keep(D_ETS_05 D_ETS_04 D_ETS_03 D_ETS_02 D_ETS_01 D_ETS0 D_ETS_1 D_ETS_2 D_ETS_3 D_ETS_4 D_ETSrest)  ///
   coeflabels(  D_ETS_05 = "2006"             ///
   D_ETS_04 = "2007"             ///
   D_ETS_03 = "2008"                   ///
   D_ETS_02 = "2009"              ///
   D_ETS_01  = "2010"             ///
   D_ETS0  = "Piloting"              ///
   D_ETS_1  = "2012"              ///    
   D_ETS_2  = "2013"              ///
   D_ETS_3    = "Trading"            ///
   D_ETS_4    = "2015"            ///
   D_ETSrest    = "2016" )            ///
   vertical                       ///
   yline(0)                             ///
   xline(6)                             ///
   xline(9)                             ///
   ytitle("碳交易对全要素生产率的影响")                 ///
   xtitle("年份") ///
   addplot(line @b @at)                 ///
   level(95)                    ///                     //设置置信区间
   ciopts(recast(rcap))                 ///
   rescale(1)                         ///
   scheme(s1mono) 

   
   
// 描述性统计
sum TFP D_ETS $X2

//图1的数据 (不同省份的 ＰＳＭ 权重份额城市级数据，加总到了省份)
use dataprocessing3, clear
keep if year==2010
bys province: egen sumweight=sum(_weight)
bys province: egen sumrgdp=sum(rgdp)
bys province: egen sumpopr=sum(popr)
bys province: gen  averagRGDPpC=sumrgdp/sumpopr
gsort -year
duplicates drop province, force
gsort -treatment -sumweight
keep city province sumweight averagRGDPpC

//图2的数据（广东省内不同城市的 ＰＳＭ 权重份额）
use dataprocessing3, clear
keep if province=="广东"
keep if year==2010
bys city: egen sumweight=sum(_weight)
bys city: egen averagRGDPpC=mean(rgdp/popr)
gsort -year
duplicates drop city, force
gsort -treatment -sumweight
keep city province sumweight averagRGDPpC

//图3的数据（湖北省内不同城市的 ＰＳＭ 权重份额）
use dataprocessing3, clear
keep if province=="湖北"
keep if year==2010
bys city: egen sumweight=sum(_weight)
bys city: egen averagRGDPpC=mean(rgdp/popr)
gsort -year
duplicates drop city, force
gsort -treatment -sumweight
keep city province sumweight averagRGDPpC


//模型回归-----------------------------------------------
use dataprocessing3, clear
xtset citycode year

sum TFP D_ETS $X1

//表1：考虑对TFP的影响(逐步回归) 
reghdfe TFP D_ETS 				[aweight=_weight], a(citycode year) vce(cluster provincecode)
    est store ATFP1
reghdfe TFP D_ETS 				[aweight=_weight2], a(citycode year) vce(cluster provincecode)
    est store ATFP2
reghdfe TFP D_ETS $X2 			[aweight=_weight], a(citycode year) vce(cluster provincecode)
    est store ATFP3
reghdfe TFP D_ETS $X2 			[aweight=_weight2], a(citycode year) vce(cluster provincecode)
    est store ATFP4
reghdfe TFP D_ETS_start 		[aweight=_weight], a(citycode year) vce(cluster provincecode)
    est store ATFP5
reghdfe TFP D_ETS_start 		[aweight=_weight2], a(citycode year) vce(cluster provincecode)
    est store ATFP6
reghdfe TFP D_ETS_start $X2 	[aweight=_weight], a(citycode year) vce(cluster provincecode)
    est store ATFP7
reghdfe TFP D_ETS_start $X2 	[aweight=_weight2], a(citycode year) vce(cluster provincecode)
    est store ATFP8
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se star(* 0.10 ** 0.05 *** 0.01)



//图5：动态效应
//生成多期的虚拟变量
	sort citycode year
	gen D_ETS1=0
	gen D_ETS2=0
	gen D_ETS3=0
	gen D_ETS4=0
	gen D_ETS5=0
	by citycode: gen z=_n
	gen Dtest=0
	replace Dtest=1 if D_ETS!=0
	
	by citycode: replace D_ETS1=1 if Dtest==1 & z==1 
	by citycode: replace D_ETS1=1 if Dtest-Dtest[_n-1]==1 & z>1   
	by citycode: replace D_ETS2=1 if D_ETS1[_n-1]==1
	by citycode: replace D_ETS3=1 if D_ETS2[_n-1]==1
	by citycode: replace D_ETS4=1 if D_ETS3[_n-1]==1
	by citycode: replace D_ETS5=1 if D_ETS4[_n-1]==1
	
	gen D_ETS6 =Dtest -D_ETS1 -D_ETS2 -D_ETS3 -D_ETS4 -D_ETS5
	drop z Dtest
	
xtreg TFP D_ETS1 D_ETS2 D_ETS3 D_ETS4 D_ETS5 D_ETS6 i.year [aweight=_weight],fe vce(cluster province) 
    est store ATFP1
xtreg TFP D_ETS1 D_ETS2 D_ETS3 D_ETS4 D_ETS5 D_ETS6 $X2 i.year [aweight=_weight],fe vce(cluster province) 
    est store ATFP2
esttab ATFP1 ATFP2 , b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 , b r2 se star(* 0.10 ** 0.05 *** 0.01)

coefplot, keep(D_ETS1 D_ETS2 D_ETS3 D_ETS4 D_ETS5 D_ETS6)  ///
   coeflabels(  D_ETS1 = "2011"             ///
   D_ETS2 = "2012"             ///
   D_ETS3 = "2013"                   ///
   D_ETS4 = "2014"              ///
   D_ETS5 = "2015"             ///
   D_ETS6 = "2016" )            ///
   vertical                       ///
   yline(0)                             ///
   xline(9)                             ///
   ytitle("碳交易对全要素生产率的边际影响")                 ///
   xtitle("年份") ///
   addplot(line @b @at)                 ///
   level(95)                    ///                     //设置置信区间
   ciopts(recast(rcap))                 ///
   rescale(1)                         ///
   scheme(s1mono) 


   
   
//表2：异质性分析
gen Ddeveloped = Dsz +Dbj +Dsh +Dtj +Dcq
replace Ddeveloped = 1 if citycode==4401 & year>=2014
gen Ddeveloping =Dhb +Dgd 
replace Ddeveloping = 0 if citycode==4401 

xtreg TFP Dsz Dbj Dsh Dtj Dgd Dhb Dcq i.year [aweight=_weight],fe vce(cluster province) 
    est store ATFP1
xtreg TFP Dsz Dbj Dsh Dtj Dgd Dhb Dcq $X2 i.year [aweight=_weight],fe vce(cluster province)
    est store ATFP2
xtreg TFP Ddeveloped Ddeveloping i.year [aweight=_weight],fe vce(cluster province)
    est store ATFP3
xtreg TFP Ddeveloped Ddeveloping $X2 i.year [aweight=_weight],fe vce(cluster province)
    est store ATFP4
esttab ATFP1 ATFP2 ATFP3 ATFP4, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3 ATFP4, b r2 se star(* 0.10 ** 0.05 *** 0.01)

//图6：面板虚拟变量分析
gen post=0
replace post=1 if year>=2011
forvalue i=2011/2016 {
	gen post`i'= 1 if year==`i'
	replace post`i'=0 if post`i'==.
	}
forvalue i=2011/2016 {
	gen Ddeveloped_post`i'= Ddeveloped*post`i'
	gen Ddeveloping_post`i'= Ddeveloping*post`i'
	replace Ddeveloped_post`i'=0 if Ddeveloped_post`i'==.
	replace Ddeveloping_post`i'=0 if Ddeveloping_post`i'==.
	}
xtreg TFP Ddeveloped_post* Ddeveloping_post* i.year [aweight=_weight],fe vce(cluster province)
    est store ATFP5	
xtreg TFP Ddeveloped_post* Ddeveloping_post* $X2 i.year [aweight=_weight],fe vce(cluster province)
	est store ATFP6
esttab ATFP5 ATFP6, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP5 ATFP6, b r2 se star(* 0.10 ** 0.05 *** 0.01)

esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6, b r2 se star(* 0.10 ** 0.05 *** 0.01)


coefplot, keep(Ddeveloped_post*)  ///
   coeflabels(	Ddeveloped_post2011 = "2011"             ///
	Ddeveloped_post2012 = "2012"             ///
	Ddeveloped_post2013 = "2013"             ///
	Ddeveloped_post2014 = "2014"             ///
	Ddeveloped_post2015 = "2015"             ///
	Ddeveloped_post2016 = "2016"             ///
	)            ///
    vertical                       ///
    yline(0)                             ///
    xline(9)                             ///
    ytitle("发达地区碳交易对TFP的边际影响")                 ///
    xtitle("年份") ///
    addplot(line @b @at)                 ///
    level(95)                    ///                     //设置置信区间
    ciopts(recast(rcap))                 ///
    rescale(1)                         ///
    scheme(s1mono) 

coefplot, keep(Ddeveloping_post*)  ///
   coeflabels(	Ddeveloping_post2011 = "2011"             ///
	Ddeveloping_post2012 = "2012"             ///
	Ddeveloping_post2013 = "2013"             ///
	Ddeveloping_post2014 = "2014"             ///
	Ddeveloping_post2015 = "2015"             ///
	Ddeveloping_post2016 = "2016"             ///
	)            ///
    vertical                       ///
    yline(0)                             ///
    xline(9)                             ///
    ytitle("欠发达地区碳交易对TFP的边际影响")                 ///
    xtitle("年份") ///
    addplot(line @b @at)                 ///
    level(95)                    ///                     //设置置信区间
    ciopts(recast(rcap))                 ///
    rescale(1)                         ///
    scheme(s1mono) 



// // 机制分析-----------------------------------------------
// sgmediation TFP, mv(lncappC) iv(D_ETS) cv($X2)
// xtreg TFP D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP1
// xtreg gdp2ndp D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP2
// xtreg TFP gdp2ndp D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP3
// esttab ATFP1 ATFP2 ATFP3, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
// esttab ATFP1 ATFP2 ATFP3, b r2 se star(* 0.10 ** 0.05 *** 0.01)	     //
//
//
// xtreg lnCO2 D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP1
// xtreg lnrgdp D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP2
// xtreg lnrgdppC D_ETS lnrFDIpC r_unemp lnrfiscaledupG lnrfiscalscipG i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP3
// esttab ATFP1 ATFP2 ATFP3, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
// esttab ATFP1 ATFP2 ATFP3, b r2 se star(* 0.10 ** 0.05 *** 0.01)	 
//
//
//
// xtreg lnindpowercsp D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lncglng D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lnlpg D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lncappG D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lnemppG D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lncappC D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lnemppC D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// xtreg lnrcap D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//
//
//
//
// reghdfe TFP D_ETS $X2 [aweight=_weight],a(citycode year) vce(cluster provincecode)
//     est store ATFP1
// reghdfe innovation l(0,1,2,3,4,5).D_ETS $X2 [aweight=_weight],a(citycode year) vce(cluster provincecode)
//     est store ATFP2
// reghdfe TFP D_ETS innovation $X2 [aweight=_weight],a(citycode year) vce(cluster provincecode)
//     est store ATFP3
// esttab ATFP1 ATFP2 ATFP3, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
// esttab ATFP1 ATFP2 ATFP3, b r2 se star(* 0.10 ** 0.05 *** 0.01)	 
//
// //碳交易价格的影响
// gen interaction=lnETSvolumepG*lnETSprice
// xtreg TFP lnETSvolumepG i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP1
// xtreg TFP lnETSvolumepG $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP2
// // xtreg TFP lnETSprice i.year [aweight=_weight],fe vce(cluster provincecode)
// //     est store ATFP3
// // xtreg TFP lnETSprice $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
// //     est store ATFP4
// xtreg TFP lnETSvolumepG lnETSprice i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP5
// xtreg TFP lnETSvolumepG lnETSprice $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP6
// xtreg TFP lnETSvolume lnETSprice i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP7
// xtreg TFP lnETSvolume lnETSprice $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
//     est store ATFP8
// esttab ATFP1 ATFP2 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
// esttab ATFP1 ATFP2 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se star(* 0.10 ** 0.05 *** 0.01)	
//	


///6、2005-2016空间溢出效应-----------------------------------------------
clear *
use dataprocessing3,clear
xtbalance,range(2005 2016) miss(TFP D_ETS $X2 )  //处理成平衡数据
bys year:sum citycode lnrgdppC gdp2ndp lnrFDIpC r_unemp lnrfiscaledupG lnrfiscalscipG  //243个城市
bys citycode: egen meanGDP=mean(gdp)												//GDP在年份的均值，用于之后的计算
xtset citycode year 
save datap3balance0516,replace

*先选出各年数据中的重叠城市														//似乎XTBALANCE已经搞定了
forval i = 2005/2016 {
	preserve
	keep if year==`i'
	duplicates drop city, force
	sort citycode
	keep citycode
	save WcityID`i', replace
	restore
}
use WcityID2005,clear
forval i = 2006/2016{
	merge 1:1 citycode using WcityID`i'
	drop if _merge!=3
	drop _merge
}
save WcityID2005-2016,replace



//PSM空间回归
//2008
use  datap3balance0516.dta, clear
keep  if year==2008                                                      //时间
set   seed 10101
gen   ranorder=runiform()
sort  ranorder
// psmatch2 treatment $X1 , outcome(TFP) n(4) ate ties logit               //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.1)  ate               //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.25) ate                    //卡尺内进行k近邻匹配
// psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.07)  ate                 //核匹配   
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
// psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配                 
psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white))  
psgraph, bin (20)   graphregion(color(white)) 
keep  citycode _weight  
rename _weight _weight2008                       
save  psm2008.dta, replace

//2009
use  datap3balance0516.dta, clear
keep  if year==2009                                                      //时间
set   seed 10101
gen   ranorder=runiform()
sort  ranorder
// psmatch2 treatment $X1 , outcome(TFP) n(4) ate ties logit common              //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.25)  ate               //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.15) ate                    //卡尺内进行k近邻匹配
psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.02)  ate  common              //核匹配
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
//psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配
// psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white))
psgraph, bin (20)  graphregion(color(white)) 
keep  citycode _weight
rename _weight _weight2009
save  psm2009.dta, replace

//2010
use  datap3balance0516.dta, clear
keep  if year==2010                                                       //时间
set   seed 10101
gen   ranorder=runiform()
sort  ranorder
// psmatch2 treatment $X1 , outcome(TFP) n(5) ate ties logit common               //k近临匹配
// psmatch2 treatment $X1 , outcome(TFP) radius cal(0.1)  ate common              //卡尺匹配
// psmatch2 treatment $X1 , outcome(TFP) n(4) cal(0.25) ate common                   //卡尺内进行k近邻匹配
psmatch2 treatment  $X1, outcome(TFP) kernel bw(0.018)  ate common                //核匹配
// psmatch2 treatment $X1 , outcome(TFP) llr  ate                           //局部线性回归匹配
// psmatch2 treatment $X1 , outcome(TFP) spline  ate                           //样条匹配
// psmatch2 treatment $X1 , outcome(TFP) mahal( $X1 ) ai(4) ate                 //马氏匹配 

pstest $X1 ,both graph graphregion(color(white)) 
psgraph, bin (20)  graphregion(color(white)) 
keep  citycode _weight
rename _weight _weight2010
save  psm2010.dta, replace

//合并权重
use  datap3balance0516.dta, clear
cap drop _merge 
cap drop _weight
merge m:1 citycode using psm2008.dta
drop _merge
merge m:1 citycode using psm2009.dta
drop _merge
merge m:1 citycode using psm2010.dta
drop _merge
replace _weight2008=0 if _weight2008==.
replace _weight2009=0 if _weight2009==.
replace _weight2010=0 if _weight2010==.
gen _weight=(_weight2008 +_weight2009 +_weight2010)/3
save  datap4balance0516.dta, replace


*从空间权重矩阵中选出这些城市，生成要用的空间矩阵
use datap4balance0516, clear
keep _weight citycode year
duplicates drop citycode, force
save test.dta, replace

use citydist299,clear
rename code citycode
merge 1:1 citycode using WcityID2005-2016 
levelsof city if _merge==1,clean  //以行的形式展示字符,不带双引号
global city0=r(levels)
drop $city0
drop if _merge==1  
drop _merge 

merge 1:1 citycode using test.dta    // 如果做带权重的空间矩阵，还需要删除无权重的样本
levelsof city if _weight==0,clean  //以行的形式展示字符,不带双引号
global city0=r(levels)
drop $city0
drop if _weight==0  
drop _merge year _weight														//有权重的城市：237

drop citycode city
erase test.dta
save citydist0516,replace														//空间距离权重矩阵



spatwmat using Gravity, name(WGravity) s //237
spatwmat using citydist0516, name(Wdist) s //237
spatwmat using WReversedistance237, name(WRDist) s //237

// 看一眼
matrix list WGravity




//表4和表5：空间杜宾模型结果
use datap4balance0516.dta, clear
xtset citycode year
drop if _weight==0
/*
如果出现Weights must be constant with panels

对xsmle文件进行修改。

首先which xsmle，找到用的那个ADO的目录
然后修改：
if `panel_sd_max' > 0.0000001 & `panel_sd_max'!=. {
	display as error "Weights must be constant within panels"
	error 198	
	
原因：对标准差、方差的计算，数值解，涉及小数点，不一定刚好等于0。EXCEL示例。
*/
xsmle TFP D_ETS year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS) model(sdm)  type(ind) fe eff r
est store SPTFP1
xsmle TFP D_ETS d_lnrgdppC year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS d_lnrgdppC) model(sdm)   type(ind) fe eff r
est store SPTFP2
xsmle TFP D_ETS d_lnrgdppC d_gdp2ndp year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS d_lnrgdppC d_gdp2ndp) model(sdm)   type(ind) fe eff r
est store SPTFP3
xsmle TFP D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC) model(sdm)   type(ind) fe eff r
est store SPTFP4
xsmle TFP D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC d_r_unemp year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC d_r_unemp) model(sdm)   type(ind) fe eff r
est store SPTFP5
xsmle TFP D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC d_r_unemp d_lnrfiscaledupG year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS d_lnrgdppC d_gdp2ndp d_lnrFDIpC d_r_unemp d_lnrfiscaledupG) model(sdm)   type(ind) fe eff r
est store SPTFP6
xsmle TFP D_ETS $X2 year [aweight=_weight], wmat(WGravity) dmat(WRDist) durbin(D_ETS $X2) model(sdm) type(ind) fe eff r
est store SPTFP7
esttab SPTFP1 SPTFP2 SPTFP3 SPTFP4 SPTFP5 SPTFP6 SPTFP7, b se r2 csv star(* 0.10 ** 0.05 *** 0.01)
esttab SPTFP1 SPTFP2 SPTFP3 SPTFP4 SPTFP5 SPTFP6 SPTFP7, b se r2 star(* 0.10 ** 0.05 *** 0.01)




//表6：可能的机制（创新与产业转移）
use dataprocessing3, clear
xtset citycode year
replace G_Innovation 		= 0 if G_Innovation		==.
replace G_Utility 			= 0 if G_Utility		==.
replace G_Innovation_rate 	= 0 if G_Innovation		==.
replace G_Utility_rate 		= 0 if G_Utility		==.

gen lnG_Utility=ln(G_Utility)
gen lnG_Innovation=ln(G_Innovation)

reghdfe G_Utility D_ETS l1_ETS l2_ETS 				$X1 	[aweight=_weight], 		a(citycode year) vce(cluster provincecode)
est store SPTFP1
reghdfe G_Utility D_ETS l1_ETS l2_ETS l3_ETS l4_ETS $X1 	[aweight=_weight], 		a(citycode year) vce(cluster provincecode)
est store SPTFP2
reghdfe gdp2ndp D_ETS l1_ETS l2_ETS 			  lnrgdppC lnrFDIpC r_unemp lnrfiscaledupG lnrfiscalscipG 	[aweight=_weight], a(citycode year) vce(cluster provincecode)
est store SPTFP3
reghdfe gdp2ndp D_ETS l1_ETS l2_ETS l3_ETS l4_ETS lnrgdppC lnrFDIpC r_unemp lnrfiscaledupG lnrfiscalscipG 	[aweight=_weight], a(citycode year) vce(cluster provincecode)
est store SPTFP4
esttab SPTFP1 SPTFP2 SPTFP3 SPTFP4, b se r2 csv star(* 0.10 ** 0.05 *** 0.01)
esttab SPTFP1 SPTFP2 SPTFP3 SPTFP4, b se r2 star(* 0.10 ** 0.05 *** 0.01)




//稳健性-----------------------------------------------
save dataprocessing3.dta, replace
//安慰剂
forvalue i=1/1000{
    use dataprocessing3, clear  //调入数据
    *- 思路：打乱dummy,即将dummy的全部取值拿出暂存，然后随机赋给每一个样本

    *- 打乱dummy,即将dummy的全部取值拿出暂存
    g obs_id= _n //初始样本序号
    gen random_digit= runiform() //生成随机数
    sort random_digit  //按新生成的随机数排序
    g random_id= _n  //产生随机序号
    preserve
        keep random_id D_ETS //保留虚拟的rep78
        rename D_ETS random_D_ETS
        rename random_id id //重命名为id，以备与其他变量合并（merge）
        label var id 原数据与虚拟处理变量的唯一匹配码
        save random_D_ETS, replace
    restore 
        drop random_digit random_id D_ETS //删除原来的rep78
        rename obs_id id //重命名为id，以备与random_rep78合并（merge）
        label var id //原数据与虚拟处理变量的唯一匹配码
        save rawdata, replace 

    *- 合并，回归，提取系数
        use rawdata, clear
        merge 1:1 id using random_D_ETS,nogen
        xtreg TFP random_D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
        g _b_random_D_ETS= _b[random_D_ETS]  //提取x的回归系数
        g _se_random_D_ETS= _se[random_D_ETS] //提取x的标准误
        keep _b_random_D_ETS _se_random_D_ETS 
        duplicates drop _b_random_D_ETS, force
        save placebo`i', replace  //把第i次placebo检验的系数和标准误存起来
    }
    
*- 纵向合并1000次的系数和标准误 
use placebo1, clear
forvalue i=2/1000{
    append using placebo`i' //纵向合并1000次回归的系数及标准误
}  
 gen tvalue= _b_random_D_ETS/ _se_random_D_ETS
kdensity tvalue, xtitle("T statistic") ytitle("Distribution") saving(placebo_test, replace)  graphregion(color(white))
*-删除临时文件
forvalue i=1/1000{
    erase  placebo`i'.dta 
} 



//时间窗口的变化
use dataprocessing3.dta,clear
xtset citycode year

xtreg TFP f3.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP1
xtreg TFP f2.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP2
xtreg TFP f.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP3
xtreg TFP D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP4
xtreg TFP l.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP5
xtreg TFP l2.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP6
xtreg TFP l3.D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP7
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7, b r2 se star(* 0.10 ** 0.05 *** 0.01)


//PSM权重结果和DID+协变量只考虑一个
xtreg TFP D_ETS $X2 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP1
xtreg TFP D_ETS i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP2
xtreg TFP D_ETS $X2 i.year ,fe vce(cluster provincecode)
    est store ATFP3
esttab ATFP1 ATFP2 ATFP3, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3, b r2 se star(* 0.10 ** 0.05 *** 0.01)


//变化数据范围
xtreg TFP D_ETS i.year [aweight=_weight] if year>= 2007,fe vce(cluster provincecode)
    est store ATFP1
xtreg TFP D_ETS $X2 i.year [aweight=_weight] if year>= 2007,fe vce(cluster provincecode)
    est store ATFP2
xtreg TFP D_ETS i.year [aweight=_weight] if yea<=2014,fe vce(cluster provincecode)
    est store ATFP3
xtreg TFP D_ETS $X2 i.year [aweight=_weight] if yea<=2014,fe vce(cluster provincecode)
    est store ATFP4
xtreg TFP D_ETS i.year [aweight=_weight] if citycode!=1100 & citycode!=3100 & citycode!=4401 & citycode!=4403,fe vce(cluster provincecode)
    est store ATFP5
xtreg TFP D_ETS $X2 i.year [aweight=_weight] if citycode!=1100 & citycode!=3100 & citycode!=4401 & citycode!=4403,fe vce(cluster provincecode)
    est store ATFP6
xtreg TFP D_ETS i.year [aweight=_weight] if citycode!=1100 & citycode!=3100 & citycode!=4403 & citycode!=5000,fe vce(cluster provincecode)
    est store ATFP7
xtreg TFP D_ETS $X2 i.year [aweight=_weight] if citycode!=1100 & citycode!=3100 & citycode!=4403 & citycode!=5000,fe vce(cluster provincecode)
    est store ATFP8
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2 ATFP3 ATFP4 ATFP5 ATFP6 ATFP7 ATFP8, b r2 se star(* 0.10 ** 0.05 *** 0.01)

//全变量全样本非一阶差分
xtreg TFP D_ETS i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP1
xtreg TFP D_ETS $X1 i.year [aweight=_weight],fe vce(cluster provincecode)
    est store ATFP2
esttab ATFP1 ATFP2, b r2 se csv star(* 0.10 ** 0.05 *** 0.01)
esttab ATFP1 ATFP2, b r2 se star(* 0.10 ** 0.05 *** 0.01)