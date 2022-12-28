//
//  ViewController.swift
//  NearbyInteractionByMultipeerConnectivity
//
//  Created by AM2190 on 2021/11/17.
//

import UIKit
import MultipeerConnectivity
import NearbyInteraction

var r_for_ui: Double = 100
var offsetX: Double = 0
var offsetY: Double = 0

var istap:Int = 0

let label = UILabel()
//ちゃんとこの値が半径に反映されている

class ViewController: UIViewController {
    // MARK: - NearbyInteraction variables
    var niSession: NISession?
    var myTokenData: Data?
    
    // MARK: - MultipeerConnectivity variables
    var mcSession: MCSession?
    var mcAdvertiser: MCNearbyServiceAdvertiser?
    var mcBrowserViewController: MCBrowserViewController?
    let mcServiceType = "mizuno-uwb"
    let mcPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    // MARK: - CSV File instances
    var file: File!
    
    // MARK: - IBOutlet instances
    @IBOutlet weak var connectedDeviceNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var directionXLabel: UILabel!
    @IBOutlet weak var directionYLabel: UILabel!
    @IBOutlet weak var directionZLabel: UILabel!
//    @IBOutlet weak var r_UI_Label: UILabel!
    
    //スライダー追加時の挙動
//    @IBOutlet weak var label: UILabel!

    var drawView: DrawView?
 
//    @IBAction func sliderChanged(_ sender: UISlider) {
//        label.text = String(sender.value * 100)
//        r_for_ui = Double(sender.value) * 100
//        //ラベルに値を流し込む
//        print(r_for_ui)
//
//        // NOTE(mactkg): drawViewに対して、再描画を依頼すればOK。
//        self.drawView?.setNeedsDisplay()
//    }
    
    
    // MARK: - UI lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let drawView = DrawView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width
                                              , height: view.frame.size.height))
        //これがSubViewの大きさ
        
//        let label = UILabel()
//        label.frame = CGRect(x:200, y:400, width:160, height:30)
//        label.text = "metaBox"
//        self.view.addSubview(label)
        
        self.drawView = drawView // 作ったViewは、ViewControllerが持っておく
        // NOTE(mactkg): ここでViewController.viewにdrawViewが渡っているので、もう追加はいらない
        // NOTE(mactkg): もしsubViewから取り除きたいときは、`self.drawView?.removeFromSuperview()` になる。
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(printStack))
        drawView.addGestureRecognizer(tapGestureRecognizer)
        
        
        self.view.addSubview(drawView)

        


        }
    
    @objc private func printStack() {
            print("stack")
            istap = 1
        }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)           
        
        if niSession != nil {
            return
        }
        setupNearbyInteraction()
        setupMultipeerConnectivity()
        
        file = File.shared
    }
    
    // MARK: - Initial setting
    func setupNearbyInteraction() {
        // Check if Nearby Interaction is supported.
        guard NISession.isSupported else {
            print("This device doesn't support Nearby Interaction.")
            return
        }
        
        // Set the NISession.
        niSession = NISession()
        niSession?.delegate = self
        
        // Create a token and change Data type.
        guard let token = niSession?.discoveryToken else {
            return
        }
        myTokenData = try! NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }
    
    func setupMultipeerConnectivity() {
        // Set the MCSession for the advertiser.
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: mcPeerID, discoveryInfo: nil, serviceType: mcServiceType)
        mcAdvertiser?.delegate = self
        mcAdvertiser?.startAdvertisingPeer()
        
        // Set the MCSession for the browser.
        mcSession = MCSession(peer: mcPeerID)
        mcSession?.delegate = self
        mcBrowserViewController = MCBrowserViewController(serviceType: mcServiceType, session: mcSession!)
        mcBrowserViewController?.delegate = self
        present(mcBrowserViewController!, animated: true)
    }
    
}

// MARK: - NISessionDelegate
extension ViewController: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        var stringData = ""
        // The session runs with one accessory.
        guard let accessory = nearbyObjects.first else { return }

        if let distance = accessory.distance {
            distanceLabel.text = distance.description
            stringData += distance.description
            
            let doubleDistance = Double(distanceLabel.text!)
            r_for_ui = doubleDistance!
            
            if r_for_ui > 1{
                r_for_ui = 1
            }
            
            
//            r_UI_Label.text = r_for_ui.description
//            r_for_uiに、距離のデータを代入
            drawView?.setNeedsDisplay()

        }else {
            distanceLabel.text = "-"
//            r_UI_Label.text = "-"

        }
        stringData += ","
        
        
        if let direction = accessory.direction {
            directionXLabel.text = direction.x.description
            directionYLabel.text = direction.y.description
            directionZLabel.text = direction.z.description
            
            //オフセットの処理
            let DoffsetX = Double(directionXLabel.text!)
            let DoffsetY = Double(directionYLabel.text!)
            offsetX = DoffsetX!
            offsetY = DoffsetY!
            
            stringData += direction.x.description + ","
            stringData += direction.y.description + ","
            stringData += direction.z.description
        }else {
            directionXLabel.text = "-"
            directionYLabel.text = "-"
            directionZLabel.text = "-"
        }
        
        stringData += "\n"
        file.addDataToFile(rowString: stringData)
        
    }
    //ここに処理を書き込めば動くのではないか…？？
//    こっちも動いている
    
    
    class DrawView: UIView {
     
        override init(frame: CGRect) {
            super.init(frame: frame);
            self.backgroundColor = UIColor.clear;
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        override func draw(_ rect: CGRect) {
            // ここにUIBezierPathを記述する
            //隠す用のやつ
            let rectangle = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 350, height: 750))
            // 内側の色
            UIColor(red: 1, green: 1, blue: 1, alpha: 1).setFill()
            // 内側を塗りつぶす
            rectangle.fill()
            

            if istap == 1 {
                let rectangle = UIBezierPath(rect: CGRect(x: 50, y: 200, width: 300, height: 400))
                // 内側の色
                UIColor(red: 1, green: 1, blue: 1, alpha: 1).setFill()
                // 内側を塗りつぶす
                rectangle.fill()
                // 線を塗りつぶす
                rectangle.stroke()
                
            }
            
            // 円
            let circle = UIBezierPath(arcCenter: CGPoint(x: 200 + offsetX*200, y: 400 - offsetY*200), radius: 150 - r_for_ui*100, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
            // 内側の色
            UIColor(red: 0, green: 0, blue: 1, alpha: 0.3).setFill()
            // 内側を塗りつぶす
            circle.fill()
            // 線の色
            UIColor(red: 0, green: 0, blue: 1, alpha: 1.0).setStroke()
            // 線の太さ
            circle.lineWidth = 2.0
            // 線を塗りつぶす
            circle.stroke()
            
            
            //ラベル
            
//            let label = UILabel()
//            label.frame = CGRect(x:200 + offsetX*200, y:400 - offsetY*200, width:160, height:30)
//            label.text = "metaBox"
//            addSubview(label)
            
            
            
            //中心のやつ
            let circle_center = UIBezierPath(arcCenter: CGPoint(x: 200, y: 400), radius: 100, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
            // 線の色
            UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).setStroke()
            // 線の太さ
            circle_center.lineWidth = 1.0
            // 線を塗りつぶす
            circle_center.stroke()
            
            
            // ダミー円
//            let dam_circle = UIBezierPath(arcCenter: CGPoint(x:300 + offsetX*500, y: 600 ), radius: 50 , startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
//            // 内側の色
//            UIColor(red: 1, green: 0, blue: 0, alpha: 0.3).setFill()
//            // 内側を塗りつぶす
//            dam_circle.fill()
//            // 線の色
//            UIColor(red: 1, green: 0, blue: 0, alpha: 1.0).setStroke()
//            // 線の太さ
//            dam_circle.lineWidth = 2.0
//            // 線を塗りつぶす
//            dam_circle.stroke()
            

            
        }


    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    }
}

// MARK: - MCSessionDelegate
extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            
            do {
                try session.send(myTokenData!, toPeers: session.connectedPeers, with: .reliable)

            } catch {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.mcBrowserViewController?.dismiss(animated: true, completion: nil)
                self.connectedDeviceNameLabel.text = peerID.displayName
            }
            
        default:
            print("MCSession state is \(state)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        guard let peerDiscoverToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            print("Failed to decode data.")
            return }
        
        let config = NINearbyPeerConfiguration(peerToken: peerDiscoverToken)
        niSession?.run(config)
        
        file.createFile(connectedDeviceName: peerID.displayName)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

// MARK: - MCBrowserViewControllerDelegate
extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
    }
    
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        return true
    }
}
