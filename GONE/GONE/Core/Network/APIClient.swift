import Foundation
import Moya

nonisolated protocol APIClient {
    func request<T: TargetType, Response: Decodable>(
        _ target: T,
        responseType: Response.Type
    ) async throws -> Response
}

nonisolated final class MoyaAPIClient: APIClient {
    private let provider: MoyaProvider<MultiTarget>
    private let decoder: JSONDecoder

    init(
        provider: MoyaProvider<MultiTarget> = MoyaProvider<MultiTarget>(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    func request<T: TargetType, Response: Decodable>(
        _ target: T,
        responseType: Response.Type
    ) async throws -> Response {
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Moya.Response, Error>) in
            provider.request(MultiTarget(target)) { result in
                switch result {
                case let .success(response):
                    guard (200..<300).contains(response.statusCode) else {
                        continuation.resume(throwing: APIError.server(
                            statusCode: response.statusCode,
                            message: nil
                        ))
                        return
                    }
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: APIError.transport(error.localizedDescription))
                }
            }
        }

        do {
            return try decoder.decode(Response.self, from: response.data)
        } catch {
            throw APIError.decoding
        }
    }
}
