$.ajaxSetup({ cache: false });//キャッシュを使用しない

			$(function () {
				$.ajax({
					// url: "test.json", //取得元のURLまたはディレクトリを記載
					url: "https://xs139481.xsrv.jp/demo/htdocs_2019/common/data/jisseki.json", //取得元のURLまたはディレクトリを記載
					type: 'GET',
					cache: false,
  					dataType: 'json',

					success: function (data) {

							// 導入地域数
							$(".area-box").html(data[0].area + '地域');//〇〇地域
							$(".area-box2").html(data[0].area + '地域');//数値のみ

							// 導入事業所数
							$(".office-box").html( '約' + data[0].office + '事業所');//約〇〇事業所
							$(".office-box2").html( '約' + data[0].office);//約〇〇
							$(".office-box3").html( data[0].office + '事業所');//〇〇事業所
							$(".office-box4").html( data[0].office);//数値のみ

							// 導入ユーザー数
							$(".user-box").html(data[0].user + '名');//〇名
							$(".user-box2").html(data[0].user);//数値のみ
							$(".user-box3").html( '約' + data[0].user + '名');//約〇名

							//有料ユーザー数
							$(".paid-box").html(data[0].paid + '名');//有料ユーザー数
							$(".paid-box2").html(data[0].paid);//数値のみ

							// 無料ユーザー数
							$(".free-box").html(data[0].free + '名');//無料ユーザー数
							$(".free-box2").html(data[0].free );//数値のみ

							// いつ時点で
							$(".point-box").html(data[0].point);//0000年00月時点
							$(".point-box-en").html(data[0].pointen);//November 2023
						
						},
					error: function () {
						$(".area-box").html("[更新中です]");
						$(".area-box2").html("[更新中です]");
						$(".office-box").html("[更新中です]");
						$(".office-box2").html("[更新中です]");
						$(".office-box3").html("[更新中です]");
						$(".office-box4").html("[更新中です]");
						$(".user-box").html("[更新中です]");
						$(".user-box2").html("[更新中です]");
						$(".user-box3").html("[更新中です]");
						$(".paid-box").html("[更新中です]");
						$(".paid-box2").html("[更新中です]");
						$(".free-box").html("[更新中です]");
						$(".free-box2").html("[更新中です]");
						$(".point-box").html("[更新中です]");
						$(".point-box-en").html("[更新中です]");
					}

					
				});
			});
