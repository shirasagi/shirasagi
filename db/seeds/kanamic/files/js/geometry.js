/**********************************************************************

* Geometry.js:ウィンドウの幅、高さを取得する
* getViewAreaWidth/Height():ブラウザの表示領域の大きさを返す。
* getHorizontalScroll():水平のスクロールバーの位置を返す。
* getVerticalScroll():垂直のスクロールバーの位置を返す。

* HTML側の記述
* <script type="text/javascript" src="(jsへのパス)/Geometry.js"></script>
* <script type="text/javascript">
* Geometry.getViewAreaWidth();
* </script>
* でブラウザの表示エリアの幅・高さが取得出来ます。

* ブラウザのX軸絶対距離＝Geometry.getViewAreaWidth()+Geometry.getHorizontalScroll()
* ブラウザのY軸絶対距離＝Geometry.getViewAreaHeight()+Geometry.getVerticalScroll()
* を求めることも可能

**********************************************************************/

var Geometry=new Object();
//var Geometry={};
if(window.innerWidth != undefined)
{	//IE以外の全てのブラウザ
	Geometry.getViewAreaWidth=function(){return window.innerWidth;};
	Geometry.getViewAreaHeight=function(){return window.innerHeight;};
	Geometry.getHorizontalScroll=function(){return window.pageXOffset;};
	Geometry.getVerticalScroll=function(){return window.pageYOffset;};
}
else if(document.documentElement != undefined && document.documentElement.clientWidth)
{	//DOCTYPEを設定してあるIE6用
	Geometry.getViewAreaWidth=function(){return document.documentElement.clientWidth;};
	Geometry.getViewAreaHeight=function(){return document.documentElement.clientHeight;};
	Geometry.getHorizontalScroll=function(){return document.documentElement.scrollLeft;};
	Geometry.getVerticalScroll=function(){return document.documentElement.scrollTop};
}
else/* if(document.body.clientWidth)*/
{	
	Geometry.getViewAreaWidth=function(){return document.body.clientWidth;};
	Geometry.getViewAreaHeight=function(){return document.body.clientHeight;};
	Geometry.getHorizontalScroll=function(){return document.body.scrollLeft;};
	Geometry.getVerticalScroll=function(){return document.body.scrollTop};
}