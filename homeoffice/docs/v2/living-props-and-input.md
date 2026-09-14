# 수납·조명·입력 보완

BlenderMCP의 실제 연결/씬 조회 뒤 `art/living_props_v2.py`를 실행했다. 기존 Blender 씬/파일을 보존하고 `art/v2-living-props.blend`와 storage/storage_lid/drawer/drawer_slide/floor_lamp GLB를 별도 생성했다. asset manifest의 단순 충돌체와 lid_hinge/drawer_track/handle/interior/switch/bulb anchor는 미터 단위다. 수납함 몸체는 1.24×0.72×0.9m, 서랍장은 0.96×0.86×0.66m, 조명은 약 0.5×1.7×0.5m다.

뚜껑과 서랍은 실제 분리 메시/AnimatableBody3D로 움직인다. 동시 꺼내기는 호스트가 순서대로 판정하여 한 물건이 두 손에 들어가지 않는다. 보관 중 물건은 freeze/충돌 중지되며 열린 용기 안에 실제 모델을 표시한다. 저장/복원은 원래 ID와 내용 참조를 보존한다. 스탠드는 실제 OmniLight와 전원 상태를 연동한다. 서랍의 첫 위치가 소파에 막힌 것을 실제 ray/이동 시험에서 발견하여 거실 남서 모서리로 옮겼다.

`evidence/v2-living-props.json`은 실제 Godot/Jolt의 위치 고정 인수이며 사람 플레이 영상과 구분한다. `storage-save.test.mjs`는 엔진이 내보낸 상태의 컨테이너 왕복과 중복/중첩/금지 참조 거절을 검사한다. 키 재설정과 두 브라우저 실제 점유 시험은 `tests/v2-bindings-ownership.mjs`다. 최종 통과 여부는 해당 evidence JSON을 따른다.

`web/key-bindings.mjs`는 22개 키를 설정하고 중복을 거절하며 기기에 보존한다. Godot는 동일 물리 키 설정으로 이동/상호작용을 실행한다. 메뉴/문서에서 눌린 키는 keyup까지 재사용하지 않고, 아주 빠른 keyup→keydown도 이벤트에서 처리한다. Esc는 항상 취소/메뉴이며 마우스 조준과 클릭은 고정이다. 원격 소품은 호스트 상태의 위치/회전을 보간하며 큰 오차에서 보정한다. 완전한 클라이언트 입력 재적용/고지연 인수는 남았다.

실제 게임 캡처에서 수납함과 기존 장식 화분의 겹침을 발견해 수납함을 (-5.85, 0, 8.15)로 옮기고 서쪽을 향하도록 회전했다. 기존 화분과 소파는 보존했다. 서랍장은 (-13.6, 0, 10.75)에서 동쪽을 향한다. 구조·문·동선 설계는 유지한다.
