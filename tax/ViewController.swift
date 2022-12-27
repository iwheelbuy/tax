//
//  ViewController.swift
//  tax
//
//  Created by michael.vasiliev on 06/11/2022.
//

import UIKit

class ViewController: UIViewController {
    
    static let mikhail = "Mikhail"
    static func extraEur(name: String) -> [String: Double]  {
        if name == mikhail {
            return [
                "10": 564,
                "07": 333,
                "04": 257
            ]
        } else {
            return [:]
        }
    }
    static let currencyEur = "EUR"
    static let currencyGbp = "GBP"
    static let currencyUsd = "USD"
    static let currencies = [currencyEur, currencyGbp, currencyUsd]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var revenues = [String: Double]()
        for (revenueMonth, revenue) in exRevenues() {
            revenues[revenueMonth] = (revenues[revenueMonth] ?? 0) + revenue
        }
        for (revenueMonth, revenue) in ibRevenues() {
            revenues[revenueMonth] = (revenues[revenueMonth] ?? 0) + revenue
        }
        print("Exante\n\n")
        for (revenueMonth, revenue) in exRevenues().sorted(by: { $0.key < $1.key }) {
            print("\n", revenueMonth, revenue)
        }
        print("\n\n\nIBKR\n\n")
        for (revenueMonth, revenue) in ibRevenues().sorted(by: { $0.key < $1.key }) {
            print("\n", revenueMonth, revenue)
        }
        for name in ["Iuliia", Self.mikhail] {
            print("\n\n\nTotal for \(name)\n\n")
            for (revenueMonth, revenue) in revenues.sorted(by: { $0.key < $1.key }) {
                let personRevenue = revenue * 0.5 + (Self.extraEur(name: name)[revenueMonth] ?? 0)
                let totalTaxableAmount = Double(round(100 * personRevenue) / 100)
                let tax = Double(round(100 * totalTaxableAmount * 0.0265) / 100)
                print("\n", revenueMonth, totalTaxableAmount, tax)
            }
        }
    }
    
    func getRevenues(getEvent: (String, String) -> (event: Event, value: Double)?, lines: [String]) -> [String: Double] {
        let events = getEvents(getEvent: getEvent, lines: lines)
        let eventsSorted = events.sorted(by: {
            if $0.key.date < $1.key.date {
                return true
            } else if $0.key.date > $1.key.date {
                return false
            } else {
                return $0.key.name < $1.key.name
            }
        })
        var revenues = [String: Double]()
        for (event, values) in eventsSorted {
            let received = values.reduce(0, +)
            let revenue = received / toEur(event: event)
            revenues[event.revenueMonth] = (revenues[event.revenueMonth] ?? 0) + revenue
        }
        return revenues
    }
    
    func getEvents(getEvent: (String, String) -> (event: Event, value: Double)?, lines: [String]) -> [Event: [Double]] {
        var events = [Event: [Double]]()
        for line in lines {
            for currency in Self.currencies {
                if let (event, value) = getEvent(line, currency) {
                    if let values = events[event] {
                        events[event] = (values + [value]).sorted(by: >)
                    } else {
                        events[event] = [value]
                    }
                }
            }
        }
        return events
    }
    
    func getLines(_ name: String) -> [String] {
        let url = Bundle.main.url(forResource: name.components(separatedBy: ".")[0], withExtension: name.components(separatedBy: ".")[1])!
        let string = try! String(contentsOf: url, encoding: .utf8)
        return string.components(separatedBy: "\n")
    }
    
    func exRevenues() -> [String: Double] {
        return getRevenues(getEvent: getExEvent, lines: getLines("ex.txt"))
    }
    
    func ibRevenues() -> [String: Double] {
        return getRevenues(getEvent: getIbEvent, lines: getLines("ib.csv"))
    }
    
    func toEur(event: Event) -> Double {
        if event.currency == Self.currencyEur {
            return 1
        } else if event.currency == Self.currencyUsd {
            // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-usd.en.html
            switch event.dateEcb {
            case "21/03/2022":
                return 1.1038
            case "22/03/2022":
                return 1.1024
            case "23/03/2022":
                return 1.0985
            case "24/03/2022":
                return 1.0978
            case "25/03/2022":
                return 1.1002
            case "01/04/2022":
                return 1.1052
            case "25/04/2022":
                return 1.0746
            case "24/05/2022":
                return 1.0720
            case "27/05/2022":
                return 1.0722
            case "09/06/2022":
                return 1.0743
            case "15/06/2022":
                return 1.0431
            case "17/06/2022":
                return 1.0486
            case "21/06/2022":
                return 1.0550
            case "22/06/2022":
                return 1.0521
            case "23/06/2022":
                return 1.0493
            case "24/06/2022":
                return 1.0524
            case "27/06/2022":
                return 1.0572
            case "28/06/2022":
                return 1.0561
            case "29/06/2022":
                return 1.0517
            case "30/06/2022":
                return 1.0387
            case "01/07/2022":
                return 1.0425
            case "27/07/2022":
                return 1.0152
            case "28/07/2022":
                return 1.0122
            case "04/08/2022":
                return 1.0181
            case "30/08/2022":
                return 1.0034
            case "22/09/2022":
                return 0.9884
            case "23/09/2022":
                return 0.9754
            case "28/09/2022":
                return 0.9565
            case "29/09/2022":
                return 0.9706
            case "30/09/2022":
                return 0.9748
            case "28/10/2022":
                return 0.9951
            case "29/11/2022":
                return 1.0366
            case "12/12/2022":
                return 1.0562
            case "19/12/2022":
                return 1.0598
            case "20/12/2022":
                return 1.0599
            case "22/12/2022":
                return 1.0633
            case "23/12/2022":
                return 1.0622
            default:
                fatalError()
            }
        } else if event.currency == Self.currencyGbp {
            // https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-gbp.en.html
            switch event.dateEcb {
            case "09/12/2022":
                return 0.85950
            default:
                fatalError()
            }
        } else {
            fatalError()
        }
    }
    
    func getExEvent(line: String, currency: String) -> (event: Event, value: Double)? {
        let components = line.components(separatedBy: "\t").map({ $0.replacingOccurrences(of: "\"", with: "") })
        guard components.count > 6 else {
            return nil
        }
        guard currency == components[7] else {
            return nil
        }
        let valueMultiplier: Double
        if components[4] == "TAX" {
            valueMultiplier = -1
        } else if components[4] == "DIVIDEND" {
            valueMultiplier = 1
        } else {
            return nil
        }
        let date = components[5].components(separatedBy: " ")[0]
        let name = components[2]
        let event = Event(currency: currency, date: date, name: name)
        let value = abs(Double(components[6])!)
        return (event, value * valueMultiplier)
    }
        
    func getIbEvent(line: String, currency: String) -> (event: Event, value: Double)? {
        let prefix: String
        let dividendsPrefix = "Dividends,Data,\(currency),"
        let withholdingTaxPrefix = "Withholding Tax,Data,\(currency),"
        let valueMultiplier: Double
        if line.hasPrefix(dividendsPrefix) {
            valueMultiplier = 1
            prefix = dividendsPrefix
        } else if line.hasPrefix(withholdingTaxPrefix) {
            valueMultiplier = -1
            prefix = withholdingTaxPrefix
        } else {
            return nil
        }
        let components = line
            .replacingOccurrences(of: prefix, with: "")
            .components(separatedBy: ",")
            .filter({ $0.isEmpty == false })
        let date = components[0]
        let name = components[1].components(separatedBy: " ")[0]
        let event = Event(currency: currency, date: date, name: name)
        let value = abs(Double(components[2])!)
        return (event, value * valueMultiplier)
    }
}

struct Event: Hashable {
    
    let currency: String
    let date: String
    let name: String
    
    var dateEcb: String {
        return date.components(separatedBy: "-").reversed().joined(separator: "/")
    }
    
    var revenueMonth: String {
        return date.components(separatedBy: "-")[1]
    }
}
