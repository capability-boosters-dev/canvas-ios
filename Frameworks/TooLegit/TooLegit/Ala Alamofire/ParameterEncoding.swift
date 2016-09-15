// ParameterEncoding.swift
//
// Copyright (c) 2014–2015 Alamofire Software Foundation (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
    HTTP method definitions.

    See https://tools.ietf.org/html/rfc7231#section-4.3
*/
public enum Method: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

// MARK: ParameterEncoding

/**
    Used to specify the way in which a set of parameters are applied to a URL request.

    - `URL`:             Creates a query string to be set as or appended to any existing URL query for `GET`, `HEAD`, 
                         and `DELETE` requests, or set as the body for requests with any other HTTP method. The 
                         `Content-Type` HTTP header field of an encoded request with HTTP body is set to
                         `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification
                         for how to encode collection types, the convention of appending `[]` to the key for array
                         values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested
                         dictionary values (`foo[bar]=baz`).

    - `URLEncodedInURL`: Creates query string to be set as or appended to any existing URL query. Uses the same
                         implementation as the `.URL` case, but always applies the encoded result to the URL.

    - `JSON`:            Uses `NSJSONSerialization` to create a JSON representation of the parameters object, which is 
                         set as the body of the request. The `Content-Type` HTTP header field of an encoded request is 
                         set to `application/json`.

*/
public enum ParameterEncoding {
    case URL
    case URLEncodedInURL
    case JSON
    
    func encodesParametersInURL(method: Method) -> Bool {
        if case .URLEncodedInURL = self {
            return true
        }
        
        switch (self, method) {
        case (.URL, .GET), (.URL, .HEAD), (.URL, .DELETE):
            return true
        default:
            return false
        }

    }
    
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sort(<) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }

    
    public func URLWithURL(URL: NSURL, method: Method, encodingParameters parameters: [String: AnyObject]) -> NSURL {
        guard parameters.count > 0 else { return URL }
        guard encodesParametersInURL(method) else { return URL }
        
        guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) else { return URL }
        
        let percentEncodedQuery = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
        components.percentEncodedQuery = percentEncodedQuery
        return components.URL ?? URL
    }
    
    func contentType(method: Method) -> String? {
        guard !encodesParametersInURL(method) else { return nil }
        
        switch self {
        case .URL:
            return "application/x-www-form-urlencoded; charset=utf-8"
        case .JSON:
            return "application/json"
        default:
            return nil
        }
    }
    
    func body(method: Method, encodingParameters parameters: [String: AnyObject]) throws -> NSData? {
        guard !encodesParametersInURL(method) && !parameters.isEmpty else { return nil }

        switch self {
        case .URL:
            let encoded = query(parameters)
            return encoded.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        case .JSON:
            let options = NSJSONWritingOptions()
            return try NSJSONSerialization.dataWithJSONObject(parameters, options: options)
        default:
            return nil
        }
    }

    /**
        Creates percent-escaped, URL encoded query string components from the given key-value pair using recursion.

        - parameter key:   The key of the query component.
        - parameter value: The value of the query component.

        - returns: The percent-escaped, URL encoded query string components.
    */
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    /**
        Returns a percent-escaped string following RFC 3986 for a query string key or value.

        RFC 3986 states that the following characters are "reserved" characters.

        - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
        - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

        In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
        query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
        should be percent-escaped in the query string.

        - parameter string: The string to be percent-escaped.

        - returns: The percent-escaped string.
    */
    func escape(string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)

        var escaped = ""

        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinense characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================

        if #available(iOS 8.3, OSX 10.10, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex

            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = startIndex..<endIndex

                let substring = string.substringWithRange(range)

                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring

                index = endIndex
            }
        }

        return escaped
    }
}
