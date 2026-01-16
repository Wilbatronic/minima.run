import MultipeerConnectivity
import Combine

/// "The Neural Link"
/// Provides instant, serverless, offline-first syncing between Devices (Mac <-> iPhone).
/// Uses Wi-Fi/Bluetooth peer-to-peer mesh. 0ms Latency. Private.
public class Synapse: NSObject, ObservableObject {
    public static let shared = Synapse()
    
    // Config
    private let serviceType = "minima-sync"
    private let myPeerId = MCPeerID(displayName: Host.current().localizedName ?? "Minima Device")
    
    // Mesh
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    private var session: MCSession
    
    @Published public var connectedPeers: [MCPeerID] = []
    
    // Data Stream
    public let incomingThoughts = PassthroughSubject<String, Never>()
    
    public override init() {
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }
    
    public func start() {
        print("[Synapse] Opening Neural Link...")
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    public func stop() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    /// Broadcast a thought/context to all nearby devices instantly.
    public func broadcast(thought: String) {
        guard !session.connectedPeers.isEmpty else { return }
        
        if let data = thought.data(using: .utf8) {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
                print("[Synapse] Broadcasted \(data.count) bytes to mesh.")
            } catch {
                print("[Synapse] Failed to broadcast: \(error)")
            }
        }
    }
}

// MARK: - MCSessionDelegate
extension Synapse: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
        switch state {
        case .connected:
            print("[Synapse] Connected to: \(peerID.displayName)")
        case .connecting:
            print("[Synapse] Linking with: \(peerID.displayName)...")
        case .notConnected:
            print("[Synapse] Lost link with: \(peerID.displayName)")
        @unknown default: break
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let str = String(data: data, encoding: .utf8) {
            print("[Synapse] Thought received from \(peerID.displayName)")
            // Route to Brain
            self.incomingThoughts.send(str)
        }
    }
    
    // Boilerplate defaults
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Browser/Advertiser Delegate (Auto-Join Logic)
extension Synapse: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    // Advertiser: Accept all invites automatically (It's my own device mesh)
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[Synapse] Accepting link from \(peerID.displayName)")
        invitationHandler(true, self.session)
    }
    
    // Browser: Invite everyone found
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("[Synapse] Found peer: \(peerID.displayName). Inviting...")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[Synapse] Peer lost: \(peerID.displayName)")
    }
}
