/**********************************************************************

*addLayer.js：HTMLの上に<div>ブロックを追加する
*addLayer(スクロールX,領域の幅,スクロールY,表示領域の高さ)

**********************************************************************/
// <![CDATA[
var layerflag;
function addlayer(scrollX,viewX,scrollY,viewY){
	//レイヤーが表示されていない時のレイヤーを追加
	if(!layerflag){
		//レイヤーを設定する
		layer = document.createElement('div');
		layer.id="loginLayer"; //生成するレイヤー名
		layer.style.position="absolute";
		layer.style.display="block";
		layer.style.zIndex="100";
		layer.style.width="100%";
		layer.style.height="100%";
		layer.style.top=scrollY+'px'; //y軸のポジション
		layer.style.left=scrollX+'px'; //x軸のポジション
		document.getElementsByTagName('body')[0].appendChild(layer);
		layerflag=true;
		var login = new SWFObject("flash/login2010_0.swf", "login", "100%", "100%", "9", "#FFFFFF");
		login.addParam("wmode","transparent"); //透明表示モードにする
		login.addParam("allowscriptaccess","always"); //FlashからのJSを有効にする
		login.write("loginLayer");
	//レイヤーが表示されている時にレイヤーを削除
	}else{
		removelayer();
	}
}

function removelayer(){
	document.getElementsByTagName('body')[0].removeChild(layer);
	layerflag=false;
	
}
// ]]>
