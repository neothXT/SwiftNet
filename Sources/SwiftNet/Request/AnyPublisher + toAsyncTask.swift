//
//  AnyPublisher + toAsyncAwait.swift
//
//
//  Created by Maciej Burdzicki on 06/09/2023.
//

import Combine

public extension AnyPublisher {
    
    /// Converts publisher to async/await task
    func toAsyncTask() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            
            cancellable = first()
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: SNError(type: .finishedWithoutValue))
                        }
                    }
                    cancellable?.cancel()
                } receiveValue: { output in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(output))
                }
        }
    }
}
