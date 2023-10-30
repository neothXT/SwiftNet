//
//  SNSessionDelegate.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 22/06/2021.
//

import Foundation
import Combine

public class SNSimpleSessionDelegate: NSObject, URLSessionTaskDelegate {
	let uploadProgress: PassthroughSubject<(id: Int, progress: Double), Never> = .init()
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		uploadProgress.send((id: task.taskIdentifier, progress: task.progress.fractionCompleted))
	}
}

final public class SNSessionDelegate: SNSimpleSessionDelegate {
	private let certExplorer = CertificateExplorer()
	private let mode: PinningMode
	private let excludedSites: [String]
	
	private lazy var pinnedCerts = certExplorer.fetchCertificates()
	private lazy var pinnedKeys = certExplorer.fetchSLLKeys()
	
	public init(mode: PinningMode, excludedSites: [String]) {
		self.excludedSites = excludedSites
		self.mode = mode
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		
		var result = true
		
		// Check if server got any security certificates
		guard let trust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0 else {
			completionHandler(.cancelAuthenticationChallenge, nil)
			return
		}
		
		let challengeCompletion: (ChallengeResult, Bool) -> Void = { challengeResult, execute in
			result = challengeResult != .failure
			
			if !execute { return }
			
			switch challengeResult {
			case .success:
				completionHandler(.useCredential, URLCredential(trust: trust))
				
			case .ignored:
				completionHandler(.performDefaultHandling, nil)
				
			case .failure:
				completionHandler(.cancelAuthenticationChallenge, nil)
			}
		}
		
		if let baseURL = task.originalRequest?.url?.baseURL?.absoluteString, excludedSites.contains(baseURL) {
			challengeCompletion(.ignored, true)
			return
		}
		
		challengeCertificateIfNeeded(trust: trust, completionHandler: challengeCompletion)
		
		if !result { return }
		
		challengeKeyIfNeeded(trust: trust, completionHandler: challengeCompletion)
	}
	
	private func challengeCertificateIfNeeded(trust: SecTrust, completionHandler: @escaping (ChallengeResult, Bool) -> Void) {
		if !mode.contains(.certificate) { completionHandler(.ignored, false); return }
		
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0) else {
			completionHandler(.failure, true)
			return
		}
		
		completionHandler(pinnedCerts.contains(serverCert) ? .success: .failure, !pinnedCerts.contains(serverCert))
	}
	
	private func challengeKeyIfNeeded(trust: SecTrust, completionHandler: @escaping (ChallengeResult, Bool) -> Void) {
		if !mode.contains(.ssl) { completionHandler(.ignored, true); return }
		
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0),
			  let key = certExplorer.publicKey(for: serverCert) else {
			completionHandler(.failure, true)
			return
		}
		
		completionHandler(pinnedKeys.contains(key) ? .success: .failure, true)
	}
}

extension SNSessionDelegate {
	enum ChallengeResult {
		case success, failure, ignored
	}
}
