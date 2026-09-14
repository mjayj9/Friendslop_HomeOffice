# STT 번들 푸시 보호 검토

2026-09-15 최초 푸시는 GitHub가 minified stt-worker.mjs 한 줄을 Mistral AI API Key로 판정하여 거절했다. 허용/우회 URL을 사용하거나 저장소 보호 규칙을 해제하지 않았다.

지목한 37번째 줄의 독립된 32자리 영숫자 29개를 주변 코드·해시로 검사했다. 해당 값은 Transformers.js의 공개 모델 클래스명(예: Mistral3ForConditionalGeneration) 및 Whisper 타임스탬프 오류 안내의 공개 gist 식별자였다. 설치된 4.2.0 소스 models/mistral3/modeling_mistral3.js와 models/whisper/modeling_whisper.js에서 확인했다. 사용자 API 키를 입력하거나 포함한 경로가 아니다.

라이브러리를 검토 가능한 줄 구분/원본 이름 형태로 다시 번들링했다. 문자열을 숨기거나 인코딩하여 보호를 피하지 않았으며 API 키 검사를 끄지 않았다. 동일한 Whisper 모델과 실행 설정을 유지한다. 재번들된 worker의 실제 인식 회귀는 별도 시험에 기록한다.

줄 구분 후 재시도에서도 동일 오류가 발생했고 GitHub가 지목한 정확한 30918행은 `mistral3`의 공개 시각 모델 클래스 등록이었다. 이 게임은 해당 시각 모델을 사용하지 않으므로 재현 가능한 번들 스크립트에서 그 사용하지 않는 등록 항목을 제거했다. 비밀 문자열을 분할/인코딩한 것이 아니며 사용 가능한 Whisper ASR 경로는 유지했다. 저장소 보호를 해제하거나 탐지 허용 링크를 사용하지 않았다.
