import SwiftUI
import WebKit

struct DaumPostcodeResult: Equatable {
    let roadAddress: String
    let jibunAddress: String
    let zonecode: String
    let buildingName: String
    let x: Double?
    let y: Double?
}

/// 카카오(다음) 우편번호 서비스 WebView — [참고](https://nsios.tistory.com/158)
struct DaumPostcodeView: UIViewRepresentable {
    let onComplete: (DaumPostcodeResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "callBackHandler")
        configuration.userContentController = controller
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.loadHTMLString(Self.html, baseURL: URL(string: "https://t1.daumcdn.net"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private let onComplete: (DaumPostcodeResult) -> Void

        init(onComplete: @escaping (DaumPostcodeResult) -> Void) {
            self.onComplete = onComplete
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "callBackHandler",
                  let body = message.body as? [String: Any] else { return }

            let road = body["roadAddress"] as? String ?? ""
            let zone = body["zonecode"] as? String ?? ""
            guard !road.isEmpty else { return }

            onComplete(
                DaumPostcodeResult(
                    roadAddress: road,
                    jibunAddress: body["jibunAddress"] as? String ?? "",
                    zonecode: zone,
                    buildingName: body["buildingName"] as? String ?? "",
                    x: Self.double(from: body["x"]),
                    y: Self.double(from: body["y"])
                )
            )
        }

        private static func double(from value: Any?) -> Double? {
            if let number = value as? Double { return number }
            if let text = value as? String, let number = Double(text) { return number }
            return nil
        }
    }

    private static let html = """
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width,height=device-height,initial-scale=1.0,maximum-scale=1.0,user-scalable=no"/>
      <style>
        html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #fff; }
        #layer { width: 100%; height: 100%; }
      </style>
      <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    </head>
    <body>
      <div id="layer"></div>
      <script>
        function postMessageToiOS(postData) {
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.callBackHandler) {
            window.webkit.messageHandlers.callBackHandler.postMessage(postData);
          }
        }

        function initPostcode() {
          if (typeof daum === 'undefined' || typeof daum.postcode === 'undefined') {
            setTimeout(initPostcode, 120);
            return;
          }

          daum.postcode.load(function() {
            new daum.Postcode({
              oncomplete: function(data) {
                var jibunAddress = data.jibunAddress || data.autoJibunAddress || "";
                var roadAddress = data.roadAddress || data.autoRoadAddress || jibunAddress;
                postMessageToiOS({
                  roadAddress: roadAddress,
                  jibunAddress: jibunAddress,
                  zonecode: data.zonecode || "",
                  buildingName: data.buildingName || "",
                  x: data.x || "",
                  y: data.y || ""
                });
              },
              width: '100%',
              height: '100%'
            }).embed(document.getElementById('layer'));
          });
        }

        initPostcode();
      </script>
    </body>
    </html>
    """
}
