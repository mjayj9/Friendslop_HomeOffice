# 미술·자산 검수

네 이미지의 구체적인 해석과 채택/미채택은 [디자인 결정](design-decisions-ko.md)에 있다. 같은 좌표의 평면은 [층별 실행 도면](campus-plan.html), 실제 기능 경계는 [구현 지도](implementation-map-ko.md)에 연결한다.

BlenderMCP를 실제 사용했다. Blender 5.2.1 LTS / addon 1.6의 호환 경로로 기존 장면 조회, 새 장면 제작, GLB export, 렌더를 수행했다. 설치/원본 장면/리그를 교체하지 않았다. MCP viewport 캡처는 대부분 빈 그리드 또는 모델 내부의 벽만 보여 미술 합격 증거로 사용하지 않는다. 실제 출력 렌더와 Godot WebGL 캡처를 따로 열어 관찰했다.

| 제작 원본 | 게임 자산 | 출처·권리·비용 |
|---|---|---|
| art/author_v6_campus.py, campus-v6.blend | assets/v6/campus-*.glb, campus.json | 이번 작업의 신규 절차 제작. 외부 유료 자산/생성 API 미사용. Blender와 표준 PBR export. |
| art/adapt_v6_house.py, retained-home-v6.blend | assets/v6/house-v6.glb | 저장소 기존 house-v3.glb의 파생본. 원본 보존. HOME 공용 통로와 팔레트 수정. |
| art/adapt_v6_site.py, site-v6.blend | assets/v6/grounds-v6.glb | 기존 부지의 파생본. 지하 개구와 통로 변경. |
| art/author_v6_passage.py, passage-v6.blend | assets/v6/passage.glb/json | 신규 제작. 문턱 세 곳의 실제 경사와 collider. |
| art/adapt_v6_facilities.py, retained-facilities-v6.blend | assets/v6/facilities-v6.glb | 기존 시설 파생본. 정적 메시 병합, 변기 뚜껑·물·방송 ON AIR 동적 노드 보존. |
| 기존 male GLB / V5 파생 rig·가구 | 기존 assets 경로 유지 | 새 캐릭터로 대체하지 않았다. 개별 원본의 확인 한계와 라이선스는 기존 third-party-notices.md 보존. |
| 사용자 참고 이미지 네 장 | 게임/공개 저장소에 이미지 복사 없음 | 형태·색·동선 참고만. 원본 이미지 재배포 권리를 추정하지 않는다. |

스케일은 m, Godot Y up / Blender Z up 변환은 glTF exporter가 담당한다. sRGB 제안색을 Blender의 선형 BSDF 값으로 변환한다. unsupported 절차 shader 대신 표준 Base Color/Roughness/Alpha를 사용한다. geometry bevel과 실제 다리/지지 부피는 유지한다.

최신 Blender 렌더: [campus-blender-final.png](../../evidence/v6/campus-blender-final.png). 크림 벽, 목재 창틀, 세이지 코어·테라스, 테라코타 띠, 줄무늬 차양, 둥근 식재와 옥상 퍼골라를 확인했다. 렌더는 조감 검토용이며 실시간 광원 품질의 증거가 아니다. 실제 브라우저에서는 [로비/회의/층별 화면](../../evidence/v6/campus-browser-final/report.json)을 기준으로 한다.

남은 미술 문제: 반복되는 6층 입면, 단순한 화장실 설비와 옥상 식재, 실시간 실내의 평평한 명암. 첨부 사진의 세밀한 수공예 표면·빛 수준에 도달했다고 판정하지 않는다. 베이크 광원/LOD/자산 스트리밍, 대표 가구·캐릭터 접촉 근접 비교와 사용자 재확인이 남아 있다. DOF나 과한 모션블러로 이를 숨기지 않았다.

기본 그래픽의 실제 WebGL 비교: [카페](../../evidence/v6/campus-balanced/01-cafe.png), [회의실](../../evidence/v6/campus-balanced/03-meeting-interior.png), [보행 통로와 외관](../../evidence/v6/campus-balanced/00-campus-approach.png). 그림자·목재 창틀·실제 테이블 지지와 크림/세이지 팔레트는 보이지만 실내 표면과 간접 명암은 단조롭다. 이를 사진 수준의 마감으로 판정하지 않았다. 기본 그래픽에서도 3개 접근 흐름이 통과했다.
