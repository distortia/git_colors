# GitColors

A Phoenix LiveView application that visualizes git commit history using AI-powered analysis. GitColors transforms your commit messages into colorful, interactive displays while providing intelligent insights about your development patterns.


This project was mainly an investigation into the capabilities of Copilot and Claude Sonnet 4

## 🌟 Features

### 🎨 **Visual Commit Display**
- **Color-coded commits**: Each commit gets a unique color based on its git hash
- **Real-time rotation**: Watch your commit history come alive with animated color transitions
- **Interactive interface**: Browse through your repository's commit history with smooth LiveView updates

### 🤖 **AI-Powered Commit Analysis**
- **Bumblebee Integration**: Local AI processing using Hugging Face models
- **Sentiment Analysis**: Understand the emotional tone of your commit messages (positive, neutral, negative)
- **Commit Type Classification**: Automatically categorize commits (feat, fix, docs, chore, etc.)
- **Complexity Assessment**: Analyze technical scope and complexity of changes
- **AI Detection**: Identify potentially AI-generated commit messages with sophisticated heuristics

### 📊 **Comprehensive Analytics**
- **Word Count Statistics**: Track message verbosity and communication patterns
- **Breaking Change Detection**: Identify commits that introduce breaking changes
- **Development Insights**: Understand your coding patterns and commit behavior
- **Real-time Updates**: All analysis happens instantly as you browse commits

### 🔧 **Technical Excellence**
- **Robust Fallback System**: Rule-based analysis when AI models aren't available
- **GenServer Architecture**: Supervised AI model management with graceful error handling
- **Comprehensive Testing**: 74+ test cases covering all analysis functions
- **Security Analysis**: Integrated Sobelow for Phoenix security scanning
- **Code Quality**: Clean code following Elixir best practices (Credo compliant)

### 🏗️ **Architecture & Performance**
- **Phoenix LiveView**: Real-time, interactive web interface
- **Supervised Processes**: Reliable AI model loading and management
- **Efficient Processing**: Fast commit analysis with smart caching
- **Error Resilience**: Graceful degradation when components fail

## 🚀 Getting Started

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## 🛠️ Development

```bash
# Run all tests
mix test

# Run code quality checks
mix precommit

# Run security analysis
mix security

# Format code
mix format
```

## 📋 Requirements

This currently only supports local git repositories. Ensure you have:
- Elixir 1.15+
- Phoenix 1.8+
- Git repository access
- Local file system permissions

## 🔮 AI Models

GitColors uses the Cardiff NLP Twitter RoBERTa model for sentiment analysis, with intelligent fallback to rule-based classification when models aren't available.

