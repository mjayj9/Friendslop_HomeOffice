# V5 검수 증거

각 JSON의 Build ID와 실행 환경을 기준으로 판정한다. 이전 빌드나 실패 기록은 역사 증거이며 최신 통과로 간주하지 않는다.

현재 빌드의 engine-regression.json, wardrobe-browser-final, placement-browser-wardrobe-build, retained-v4-browser-wardrobe-build와 기본 소파의 seating-browser-front 기록에는 선택한 실제 화면 녹화를 함께 보관한다. 반복 시도의 page@*.webm 녹화는 로컬에 유지하고 Git에는 포함하지 않는다. 나머지 보고서·로그·스크린샷은 실패와 재시험을 추적하도록 보존한다. publication에는 실제 공개 페이지에서 새로 수행한 검사만 저장한다.

references는 연구를 위해 브라우저에서 관찰한 화면과 재생 시각 기록이다. 원본 영상 자체는 배포하지 않는다. 연구 완결 여부는 docs/v5/research-observations-ko.md에 따르며, 재생 실패를 시청 완료로 해석하지 않는다.
