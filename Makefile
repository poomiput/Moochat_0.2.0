# MooChat Flutter Development Makefile

.PHONY: help emu device clean build test

help: ## Show this help message
	@echo "🚀 MooChat Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

emu: ## Run app on emulator
	@echo "🚀 Starting MooChat on Emulator..."
	flutter run -d emulator-5554 --flavor development

device: ## Run app on physical device
	@echo "📱 Starting MooChat on Android Device..."
	flutter run -d "SM G998B" --flavor development

clean: ## Clean and get dependencies
	@echo "🧹 Cleaning project..."
	flutter clean && flutter pub get

build: ## Build development APK
	@echo "🔨 Building development APK..."
	export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" && cd android && ./gradlew assembleDevelopmentDebug

test: ## Run tests
	@echo "🧪 Running tests..."
	flutter test

deps: ## Get dependencies
	@echo "📦 Getting dependencies..."
	flutter pub get

gen: ## Generate code (build_runner)
	@echo "⚙️ Generating code..."
	flutter packages pub run build_runner build