//
//  CNSessionDelegate.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 22/06/2021.
//

import Foundation

final public class CNSessionDelegate: NSObject, URLSessionTaskDelegate {
	private let mode: PinningMode
	private let certNames: [String]
	
	private var _pinnedKeys: [SecKey]?
	
	private lazy var pinnedCerts: [Data] = {
		var certificates: [Data] = []
		
		certNames.forEach {
			if let certificateURL = Bundle.main.url(forResource: $0, withExtension: "cer"),
			   let certificate = try? Data(contentsOf: certificateURL) {
				certificates.append(certificate)
			}
		}
		
		return certificates
	}()
	
	private lazy var pinnedKeys: [SecKey] = {
		if let pinnedKeys = _pinnedKeys {
			return pinnedKeys
		}
		
		var pinnedKeys: [SecKey] = []
		
		certNames.forEach {
			if let certificateURL = Bundle.main.url(forResource: $0, withExtension: "cer"),
			   let certificateData = try? Data(contentsOf: certificateURL) as CFData,
			   let certificate = SecCertificateCreateWithData(nil, certificateData),
			   let key = publicKey(for: certificate) {
				pinnedKeys.append(key)
			}
		}
		
		return pinnedKeys
	}()
	
	public init(mode: PinningMode, certNames: [String] = [], SSLKeys keys: [SecKey]? = nil) {
		_pinnedKeys = keys
		self.certNames = certNames
		self.mode = mode
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		
		var result = false
		
		// Check if server got any security certificates
		guard let trust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0 else {
			completionHandler(.cancelAuthenticationChallenge, nil)
			return
		}
		
		let challengeCompletion: (Bool) -> Void = {
			if !$0 {
				completionHandler(.cancelAuthenticationChallenge, nil)
				return
			}
			result = $0
		}
		
		
		challengeCertificateIfNeeded(trust: trust, completionHandler: challengeCompletion)
		challengeKeyIfNeeded(trust: trust, completionHandler: challengeCompletion)
		
		completionHandler(result ? .useCredential: .cancelAuthenticationChallenge,
						  result ? URLCredential(trust: trust): nil)
	}
	
	private func challengeCertificateIfNeeded(trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		if !mode.contains(.certificate) { completionHandler(true); return }
		
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0) else {
			completionHandler(false)
			return
		}
		
		completionHandler(pinnedCerts.contains(SecCertificateCopyData(serverCert) as Data))
	}
	
	private func challengeKeyIfNeeded(trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		if !mode.contains(.ssl) { completionHandler(true); return }
		
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0),
			  let key = publicKey(for: serverCert) else {
			completionHandler(false)
			return
		}
		
		completionHandler(pinnedKeys.contains(key))
	}
	
	private func publicKey(for certificate: SecCertificate) -> SecKey? {
		var trust: SecTrust?
		let trustStatus = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
		
		guard let trust = trust, trustStatus == errSecSuccess else { return nil }
		
		return SecTrustCopyPublicKey(trust)
	}
}
