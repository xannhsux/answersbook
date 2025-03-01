//
//  ContentView.swift
//  AnswerBook
//
//  Created by Ann Hsu on 2/28/25.
//
import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var displayMessage: String = "Think of your question and enter a number from 1 to 999"
    @State private var isLoading: Bool = false // Loading state
    
    var body: some View {
        VStack {
            Text(displayMessage)
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
            
            TextField("Enter a number from 1 to 999", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad)
            
            Button(action: {
                generateMessage()
            }) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("Get Answer")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
    }
    
    // Generate message
    func generateMessage() {
        // Check if input is valid
        guard let number = Int(userInput), number >= 1, number <= 999 else {
            displayMessage = "Please enter a valid number (1 to 999)"
            return
        }
        
        isLoading = true // Start loading
        fetchAnswerFromHuggingFace(userInput: userInput) { message in
            DispatchQueue.main.async {
                displayMessage = message
                isLoading = false // End loading
            }
        }
    }
    
    // Call Hugging Face API
    func fetchAnswerFromHuggingFace(userInput: String, completion: @escaping (String) -> Void) {
        let apiKey = "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"
        let modelName = "openai-community/gpt2" // 替换为你想要的模型名称
        let url = URL(string: "https://api-inference.huggingface.co/models/\(modelName)")! // 正确的 API 端点
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 请求体
        let body: [String: Any] = [
            "inputs": "Generate a short and abstract answer that applies to any situation.", // 输入提示
            "parameters": [
                "max_length": 20, // 生成的最大长度
                "temperature": 0.7 // 控制生成文本的随机性
            ]
        ]
        
        // 将请求体转换为 JSON 数据
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            completion("Failed to generate request")
            return
        }
        request.httpBody = httpBody
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("Request failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion("No data received")
                return
            }
            
            // 打印原始响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }
            
            // 解析响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let generatedText = json.first?["generated_text"] as? String {
                    completion(generatedText)
                } else {
                    completion("Failed to parse response")
                }
            } catch {
                completion("Response parsing failed: \(error.localizedDescription)")
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
