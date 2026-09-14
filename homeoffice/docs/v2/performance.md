# 실제 성능 기록

기기: ASUS TUF Gaming F16 FX608JMR, Intel Core i7-14650HX 16C/24T, RAM 약 32GiB, NVIDIA RTX 5060 Laptop 및 Intel UHD. Windows/Chromium D3D11. 어댑터 선택은 브라우저 자동이며 각 시험의 renderer를 별도 기록한다.

8개 독립 Chromium 프로세스가 한 PC의 자원을 공유한다. 호스트 1920×1080, 참가자는 640×360. 별도 PC 8대 성능이나 실제 사람 마이크 시험이 아니다.

| 인원 | 호스트 FPS | draw calls | 참가자 FPS |
|---|---:|---:|---:|
| 2 | 29 | 545 | 49 |
| 4 | 17 | 685 | 47 |
| 8 | 7 | 965 | 23 |

8인 호스트 반복 표본 6~7fps로 목표 미달. 입력/소유권/개인실 기능 시험 통과와 성능 합격을 구분한다. 저품질/별도 PC/동시 음성·STT·협업/공 경기의 통합 성능과 전체 메모리/대역폭/누수는 필수 미완료다.

정적 메시/재질 공유, 단순 충돌체, 물체 sleep, 가까운 조명 4개(저품질 2개), 짧은 그림자 거리, 저품질 75% 렌더 스케일을 사용한다. 방별 정밀 가시성/LOD 추가 최적화가 남았다. Godot Web staticMemory=0은 미계측이다. JS heap 수치는 WASM/GPU/전체 메모리가 아니다.

로컬 한국어 인식 동시 실행은 별도 [측정](korean-stt-measurement.md)을 참고한다.
