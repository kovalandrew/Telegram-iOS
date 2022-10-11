import Foundation
import SwiftSignalKit


struct DateResponse: Decodable {

    let abbreviation: String
    let clientIp: String
    let dayOfWeek: Int
    let dayOfYear: Int
    let weekNumber: Int
    let timezoneName: String
    let timestamp: Int32
    let dateTimeString: String
    let dateTimeUTCString: String
    let utcOffset: String

    private enum CodingKeys : String, CodingKey {
        case abbreviation
        case clientIp = "client_ip"
        case dayOfWeek = "day_of_week"
        case dayOfYear = "day_of_year"
        case weekNumber = "week_number"
        case timezoneName = "timezone"
        case timestamp = "unixtime"
        case dateTimeString = "datetime"
        case dateTimeUTCString = "utc_datetime"
        case utcOffset = "utc_offset"
    }
}

public class CurrentDateTimestampApiFetcher {

    private struct Constants {
        static let requestURLString = "http://worldtimeapi.org/api/timezone/Europe/Moscow"
    }

    var urlSession: URLSession
    var activeTask: URLSessionDataTask?

    public init() {
        self.urlSession = URLSession.shared
    }

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func getCurrentDateTimestamp() -> Signal<Int32?, NoError>  {
        return Signal<Int32?, NoError> { [weak self] subscriber in
            guard
                let self = self,
                let url = URL(string: Constants.requestURLString)
            else { return EmptyDisposable }

            self.activeTask = self.urlSession.dataTask(with: url) { data, response, error in
                Queue.mainQueue().async {
                    self.handleResponseData(data, forSubscriber: subscriber)
                }
            }

            self.activeTask?.resume()

            return ActionDisposable {
                self.activeTask?.cancel()
                self.activeTask = nil
            }
        }
    }

    private func handleResponseData(_ data: Data?, forSubscriber subscriber: Subscriber<Int32?, NoError>) {
        if let data = data, let result = try? JSONDecoder().decode(DateResponse.self, from: data) {
            subscriber.putNext(result.timestamp)
            subscriber.putCompletion()
        } else {
            subscriber.putNext(nil)
            return
        }
    }
}
