#!/bin/bash

echo "🔧 Remory 프로젝트 환경 확인"
echo "================================"

# Java 버전 확인
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
echo "현재 Java 버전: $JAVA_VERSION"

if [ "$JAVA_VERSION" != "17" ]; then
    echo "❌ Java 17이 필요합니다!"
    echo ""
    echo "해결 방법:"
    echo "macOS: brew install openjdk@17"
    echo "Linux: sudo apt-get install openjdk-17-jdk"
    echo ""
    echo "환경변수 설정:"
    echo "export JAVA_HOME=\$(brew --prefix openjdk@17)  # macOS"
    echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk  # Linux"
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
    exit 1
else
    echo "✅ Java 17이 설치되어 있습니다"
fi

# JAVA_HOME 확인
if [ -z "$JAVA_HOME" ]; then
    echo "❌ JAVA_HOME이 설정되지 않았습니다"
    exit 1
else
    echo "✅ JAVA_HOME: $JAVA_HOME"
fi

# Android SDK 확인
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "❌ Android SDK 경로가 설정되지 않았습니다"
    echo "Android Studio에서 SDK 경로를 확인하고 설정하세요"
    exit 1
else
    echo "✅ Android SDK 경로가 설정되어 있습니다"
fi

echo ""
echo "🚀 환경 설정 완료! Flutter 프로젝트를 실행할 수 있습니다."
echo "fvm flutter run 명령어를 실행하세요."
