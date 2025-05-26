import Foundation
import EventKit

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var isOptimizing: Bool = false
    @Published var events: [EKEvent] = []
    
    @Published var planningSummary: String? = nil
    @Published var showSummaryOverlay: Bool = false
    @Published var isLoadingSummary: Bool = false
    
    @Published var showQuestionOverlay: Bool = false
       @Published var isLoadingQuestionResponse: Bool = false
       @Published var questionResponse: String? = nil
    
    @Published var questionText: String? = nil
    @Published var questionAnswer: String? = nil

    
    @Published var currentWeekStart: Date = {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return calendar.date(byAdding: .day, value: 1, to: startOfWeek)! // Monday as start of week
    }()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func askScheduleQuestion() {
        isLoadingQuestionResponse = true
        questionAnswer = nil

        // Prepare URL
        guard let url = URL(string: "\(APIConstants.baseURL)/planning/ask") else {
            self.questionAnswer = "❌ Invalid URL"
            self.isLoadingQuestionResponse = false
            return
        }

        // Format EKEvents to simplified model
        struct SimpleEvent: Codable {
            let title: String
            let startDate: String
            let endDate: String
        }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current

        let simpleEvents: [SimpleEvent] = events.map {
            SimpleEvent(
                title: $0.title,
                startDate: formatter.string(from: $0.startDate),
                endDate: formatter.string(from: $0.endDate)
            )
        }

        struct RequestBody: Codable {
            let question: String
            let events: [SimpleEvent]
        }

        let requestBody = RequestBody(question: questionText!, events: simpleEvents)

        // Encode body
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            self.questionAnswer = "❌ Failed to encode request."
            self.isLoadingQuestionResponse = false
            return
        }

        // Create and send request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                defer { self.isLoadingQuestionResponse = false }

                if let error = error {
                    self.questionAnswer = "❌ Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self.questionAnswer = "❌ No response from server."
                    return
                }

                if let decoded = try? JSONDecoder().decode([String: String].self, from: data),
                   let answer = decoded["answer"] {
                    self.questionAnswer = answer
                } else if let raw = String(data: data, encoding: .utf8) {
                    print("⚠️ Unexpected raw response:", raw)
                    self.questionAnswer = "⚠️ Unexpected response:\n\(raw)"
                } else {
                    self.questionAnswer = "❌ Failed to decode response."
                }
            }
        }.resume()
    }

    func fetchEvents(for days: Int = 30) {
        let calendars = eventStore.calendars(for: .event)
        let calendar = Calendar.current

        let startOfMonday = currentWeekStart
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfMonday)!

        let predicate = eventStore.predicateForEvents(withStart: startOfMonday, end: endOfWeek, calendars: calendars)
        self.events = eventStore.events(matching: predicate)
    }

    func goToNextWeek() {
        let calendar = Calendar.current
        currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!
        fetchEvents()
    }

    func goToPreviousWeek() {
        let calendar = Calendar.current
        currentWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart)!
        fetchEvents()
    }

    func updateEvent(_ event: EKEvent, newStart: Date, newEnd: Date) {
        event.startDate = newStart
        event.endDate = newEnd

        do {
            try eventStore.save(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Error updating event: \(error)")
        }
    }

    func createEvent(title: String, start: Date, end: Date, notes: String? = nil) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = notes

        do {
            try eventStore.save(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Failed to save event: \(error)")
        }
    }

    func createEvent(at dayIndex: Int, hour: Int, title: String = "New Event") {
        let calendar = Calendar.current

        let monday = currentWeekStart
        guard let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: monday),
              let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayDate),
              let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) else {
            print("Failed to create valid date for event")
            return
        }

        createEvent(title: title, start: startDate, end: endDate)
    }

    func deleteEvent(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Failed to delete event: \(error)")
        }
    }

    func moveEvent(_ event: EKEvent, to newStartDate: Date, newEndDate: Date) {
        event.startDate = newStartDate
        event.endDate = newEndDate
        do {
            try eventStore.save(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Failed to move event: \(error)")
        }
    }

    func sendEventsToOptimizeEndpoint() {
        
        let calendar = Calendar.current
        let start = currentWeekStart
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return }

        let weekEvents = events.filter { $0.startDate >= start && $0.startDate < end }

        let formatter = ISO8601DateFormatter()

        let eventDicts: [[String: Any]] = weekEvents.map { event in
            var dict: [String: Any] = [
                "title": event.title,
                "startDate": formatter.string(from: event.startDate),
                "endDate": formatter.string(from: event.endDate),
                "isAllDay": event.isAllDay,
                "calendar": event.calendar.title
            ]

            if let location = event.location {
                dict["location"] = location
            }
            if let notes = event.notes {
                dict["notes"] = notes
            }
            if let url = event.url?.absoluteString {
                dict["url"] = url
            }
            if let organizerName = event.organizer?.name {
                dict["organizerName"] = organizerName
            }
            if let organizerEmail = event.organizer?.url.absoluteString {
                dict["organizerEmail"] = organizerEmail
            }

            return dict
        }

        guard let url = URL(string: "\(APIConstants.baseURL)/optimize") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventDicts, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode event data:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Optimize request failed:", error)
                return
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let optimized = json["optimized"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.applyOptimizedEvents(optimized)
                        self.isOptimizing = false
                        self.showSummaryOverlay = false
                        
                    }
                }
            } catch {
                print("Failed to parse optimized response:", error)
            }
        }.resume()
    }
    func fetchPlanningSummary(completion: @escaping (String?) -> Void) {
        let calendar = Calendar.current
        let start = currentWeekStart
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else {
            completion(nil)
            return
        }

        let weekEvents = events.filter { $0.startDate >= start && $0.startDate < end }

        let formatter = ISO8601DateFormatter()
        let eventDicts: [[String: Any]] = weekEvents.map { event in
            var dict: [String: Any] = [
                "title": event.title,
                "startDate": formatter.string(from: event.startDate),
                "endDate": formatter.string(from: event.endDate),
                "isAllDay": event.isAllDay,
                "calendar": event.calendar.title
            ]

            if let location = event.location { dict["location"] = location }
            if let notes = event.notes { dict["notes"] = notes }
            if let url = event.url?.absoluteString { dict["url"] = url }
            if let organizerName = event.organizer?.name { dict["organizerName"] = organizerName }
            if let organizerEmail = event.organizer?.url.absoluteString { dict["organizerEmail"] = organizerEmail }

            return dict
        }

        guard let url = URL(string: "\(APIConstants.baseURL)/week-summary") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: eventDicts)
        } catch {
            print("❌ JSON encode failed:", error)
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request failed:", error)
                completion(nil)
                return
            }

            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let summary = json["summary"] as? String {
                    completion(summary)
                } else {
                    completion(nil)
                }
            } catch {
                print("❌ Failed to decode JSON:", error)
                completion(nil)
            }
        }.resume()
    }
    func applyOptimizedEvents(_ optimizedEvents: [[String: Any]]) {
        let formatter = ISO8601DateFormatter()

        for optimized in optimizedEvents {
            guard
                let title = optimized["title"] as? String,
                let startDateStr = optimized["startDate"] as? String,
                let endDateStr = optimized["endDate"] as? String,
                let newStart = formatter.date(from: startDateStr),
                let newEnd = formatter.date(from: endDateStr)
            else {
                continue
            }

            if let matchingEvent = self.events.first(where: { event in
                event.title == title &&
                event.calendar.allowsContentModifications &&
                !event.isAllDay
            }) {
                print("✅ Updating event: \(title), \(newStart) - \(newEnd)")
                updateEvent(matchingEvent, newStart: newStart, newEnd: newEnd)
            } else {
                print("⚠️ Could not update '\(title)': No editable matching event found or it's all-day.")
            }
        }
    }
}
