# Stateflow 그래픽 설계 표준

## 1. 목적과 적용 범위

이 문서는 이 프로젝트에서 새로 만들거나 수정하는 모든 Stateflow 차트의 그래픽 품질 기준을
정의한다. 차트는 논리적으로 동작하는 것만으로 완료된 것이 아니다. 상태 계층, 정상 흐름,
예외 흐름, 전이 우선순위와 조건을 사람이 화면에서 검토할 수 있도록 배치하고 검증해야 한다.

이 기준은 다음 작업에 모두 적용한다.

- 새 Stateflow 차트 생성
- 기존 차트의 상태 또는 전이 추가
- 기존 차트의 그래픽 레이아웃 보정
- 하위 상태, 서브차트 또는 병렬 상태 추가

레이아웃만 수정하는 작업에서는 상태 이름, 상태 액션, 전이 조건과 액션, 이벤트, 데이터,
계층 관계, 전이의 Source와 Destination 및 실행 의미를 변경하지 않는다. 긴 상태 액션을
함수나 graphical function으로 옮기는 작업은 별도의 논리 리팩터링으로 취급한다.

## 2. 완료 정의

Stateflow 작업은 다음 다섯 단계가 모두 끝나야 완료로 본다.

1. **기준선 보호** — 원본 모델을 백업하고 논리 서명과 기존 테스트 결과를 기록한다.
2. **논리 생성** — 상태, 전이, 데이터, 이벤트와 동작을 구현한다.
3. **그래픽 설계** — 상태 크기와 위치, 전이 경로와 라벨 위치를 명시적으로 설계한다.
4. **자동 검사** — 프로젝트 레이아웃 검사기로 좌표 완전성, 겹침과 논리 보존을 검사한다.
5. **실행 검증** — Update Diagram, 구조 검사와 관련 회귀 시나리오를 통과한다.

논리 객체를 생성한 직후의 자동 좌표를 최종 레이아웃으로 간주하지 않는다. `Auto Arrange`는
초기 정렬 보조 수단으로 사용할 수 있지만, 이 문서의 간격·흐름·전이 경로 기준을 대신하지
않는다.

### 2.1 새 차트의 필수 산출물

새 차트는 모델 파일만 만들어서는 완료되지 않는다. 다음 세 가지 자동화 산출물을 함께
구현하고 MATLAB Project에 등록한다.

| 산출물 | 역할 | 완료 조건 |
| --- | --- | --- |
| `scripts/layout_<model>.m` | 모든 State와 Transition의 그래픽 속성과 Transition `RoutingType`을 선언적으로 배치 | 백업과 논리 서명 비교가 기본 활성화되고, 누락된 그래픽 객체가 있으면 실패 |
| `src/+amr/+stateflow/inspectGraphicalLayout.m` | 겹침, 간격, `BadIntersection`과 전이 경로의 공통 검사 | `report.HardViolationCount == 0`, advisory 항목 검토 완료 |
| `tests/unit/StateflowGraphicalLayoutTest.m` | 레이아웃 스크립트와 검사기의 재실행 가능성 검증 | 대상 차트의 테스트 케이스, Update Diagram과 논리·레이아웃 검증 통과 |

기존 차트에 State 또는 Transition을 추가한 경우에도 레이아웃 테이블과 검증 테스트를 같은
변경에서 갱신한다. 레이아웃 스크립트가 모든 그래픽 객체를 다룬다는 검사가 실패하면 새
객체에 임의 기본 좌표를 둔 채 완료하지 않는다.

현재 Mission Supervisor 차트의 레이아웃 진입점은
`scripts/layout_amr_mission_supervisor.m`이다. 이 스크립트처럼 다음 계약을 지킨다.

승인된 v07 위치·배율 수치는 `amr.stateflow.graphicalLayoutProfile`에 한 번만 정의한다.
레이아웃 스크립트, 검사기와 테스트는 이 프로필을 읽으며 새 차트나 새 Subchart도 별도 요청
없이 같은 로컬 시작점, page 비율과 viewport 완료 조건을 적용한다.

- 기본 실행에서 원본 모델 백업을 생성한다.
- 그래픽 속성을 바꾸기 전에 논리 서명을 캡처한다.
- 차트부터 가장 깊은 Composite State/Subchart까지 모든 Subviewer를 자동 수집하고,
  각 직접 자식 State와 Transition에 대응하는 레이아웃·라우팅 기록을 둔다. 특정 Region
  이름이나 고정 좌표 표에 의존하지 않는다.
- `ExecutionOrder`를 복원한 뒤 논리 서명을 다시 비교한다.
- 모든 검증이 끝나기 전에는 변경 모델을 최종 결과로 보고하지 않는다.
- `fitToView`는 저장과 검증 이후 마지막 화면 확인 단계에서만 호출한다.

공통 검사기와 단위 테스트의 기본 호출은 다음과 같다.

```matlab
report = amr.stateflow.inspectGraphicalLayout( ...
    "models/mission_supervisor/amr_mission_supervisor.slx", ...
    "MissionSupervisor");
assert(report.HardViolationCount == 0);

results = runtests("tests/unit/StateflowGraphicalLayoutTest.m");
assert(all([results.Passed]));
```

새 차트를 추가할 때는 공통 검사기를 복제하지 않는다. 해당 차트의 레이아웃 스크립트를
추가하고 `StateflowGraphicalLayoutTest.m`에 차트별 테스트 케이스를 등록한다.

## 3. 작업 전 보호 절차

기존 모델의 레이아웃을 수정하기 전에 다음을 수행한다.

1. 모델 파일과 Git 상태를 확인한다.
2. 원본 모델을 `work/backups/` 아래에 타임스탬프를 붙여 복사한다.
3. 모든 State와 Transition의 논리 서명을 수집한다.
4. 기존 테스트와 모델 Update Diagram이 통과하는지 기준선을 확인한다.

검증 완료 원본에는 레이아웃 스크립트를 직접 실행하지 않는다. 원본을 별도 후보 파일로
복사한 뒤 `ModelPath`를 명시해 전체 배치를 수행한다. 전체 배치 반복이 필요하면 이미
좌표가 변경된 후보에 계속 누적 적용하지 않고 원본에서 새 후보를 다시 만든다. Stateflow가
저장 과정에서 Subviewer 좌표를 평행이동할 수 있어 누적 적용이 외곽 lane을 증폭시킬 수 있기
때문이다.

`work/backups/`의 사본은 복구용 작업 파일이며 MATLAB Project나 Git 소스 파일로
등록하지 않는다. 사용자의 기존 변경이 있는 모델은 그 상태 그대로 백업하고, 관련 없는
변경을 되돌리지 않는다.

### 3.1 레이아웃 전 논리 서명

최소한 다음 속성을 객체 ID 또는 완전한 계층 경로와 함께 기록한다.

| 객체 | 반드시 기록할 값 |
| --- | --- |
| State | 계층 경로, 이름, LabelString/액션, Decomposition, 부모 |
| Transition | Source, Destination, LabelString, ExecutionOrder, 화면 전이 번호 |
| Data | 이름, Scope, Type, Port, 초기값 |
| Event | 이름, Scope, Trigger |

특히 각 상태에서 나가는 Transition의 기존 평가 순서를 순서가 있는 목록으로 저장한다.
그래픽 포트 위치를 바꾸면 암시적 전이 순서가 달라질 수 있으므로, 단순히 전이 개수가 같은지는
동등성 증거가 되지 않는다.

## 4. 공통 시각 구조

### 4.1 읽기 방향과 영역 분리

- 주 동작 흐름은 왼쪽에서 오른쪽으로 읽히게 배치한다.
- 정상 동작 상태는 차트의 위쪽 행에 둔다.
- 재계획, 복구, 중단과 실패 상태는 아래쪽 행에 둔다.
- 정상 흐름과 예외 흐름 사이에는 명확한 빈 통로를 둔다.
- 상위 상태와 하위 상태의 경계가 시각적으로 분명하도록 내부 여백을 둔다.
- 전이선이 다른 State의 내부를 통과하지 않게 한다.

상태 사이의 최소 여백은 상태 경계 기준으로 다음과 같다.

| 방향 | 최소 여백 |
| --- | ---: |
| 수평 | 80 px |
| 수직 | 110 px |

이 값은 최소값이다. 상태 액션이나 전이 라벨이 길면 상태 또는 통로를 더 넓힌다.
다만 하나의 명확한 순차 경로를 같은 행에 압축 배치하는 Subchart에서는 모든 State 높이와
수직 중심을 통일하고, 전이가 수평 직선이며 라벨 여백이 확보된 경우 수평 간격 25–40 px를
사용할 수 있다. 이 예외는 검사기와 결과 노트에 해당 행을 명시한 경우에만 적용한다.

### 4.2 NavigationRegion 권장 배치

NavigationRegion은 정상 흐름과 예외·복구 흐름을 다음 두 행으로 분리한다.

```text
정상 흐름
NavIdle  ─────→  Planning  ─────→  Tracking
                    ↑                  │
                    │                  ↓

예외·복구 흐름
NavFailed  ←────  Recovery  ←────  Replanning
```

실제 전이 방향과 조건은 현재 로직을 그대로 유지한다. 위 도식은 객체 위치와 라우팅 영역만
나타낸다.

| 객체 | 권장 `Position` (`[left top width height]`) |
| --- | --- |
| NavigationRegion | `[2580 300 860 500]` (상위 Chart 좌표) |
| NavIdle | `[80 100 300 130]` |
| Planning | `[530 100 330 150]` |
| Tracking | `[1040 100 380 160]` |
| NavFailed | `[80 450 360 170]` |
| Recovery | `[540 370 400 250]` |
| Replanning | `[1040 450 330 150]` |

좌표는 상태 액션의 실제 길이와 상위 차트 크기에 맞게 확대할 수 있다. 확대하더라도 정상
상단·예외 하단 구조와 최소 간격은 유지한다.

## 5. State 배치 규칙

- 모든 State의 `Position`을 명시적으로 설정한다.
- State의 `FontSize`는 기본 10으로 통일한다.
- 상태 이름과 모든 액션 문자열이 상태 경계 안에 완전히 보여야 한다.
- 긴 텍스트를 맞추기 위해 글씨를 지나치게 줄이지 않고 State의 폭과 높이를 늘린다.
- 한 State에서 `entry`, `during`, `exit` 액션은 각각 별도 줄에 둔다.
- 새 상태를 작성할 때는 한 줄에 하나의 명령만 표시되도록 세미콜론 뒤에서 줄을 나눈다.
- 기존 차트의 레이아웃만 수정할 때는 실행 표현식을 변경하지 않는다. 공백이나 줄바꿈을
  정리한 경우에는 원문과 정규화된 액션을 모두 비교하고, 별도 변경으로 기록한다.
- 상태 액션이 지나치게 커도 레이아웃 작업 중에 함수 호출로 치환하지 않는다. 함수화는
  별도 리팩터링, 별도 검증 작업으로 수행한다.
- State 폭은 이름·action의 추정 표시 폭과 기본 padding으로 정한다. 필요 폭의 3배를
  넘거나 같은 행 전체 State 폭의 50%를 넘으면 과대 폭 경고로 처리한다.
- Transition 포트를 수직으로 맞추기 위해 공통 오류 State를 정상 행 전체 폭으로 늘리지
  않는다. State 크기는 라우팅 lane이 아니다.
- 일반 Composite State는 제목 영역을 제외한 실제 내부 사용 영역에 자식 bounding box의
  중심을 맞춘다. 부모만 확대하고 자식 좌표를 그대로 두지 않는다.

상태를 배치한 뒤 모든 State의 `BadIntersection`이 `false`인지 확인한다.

## 6. Transition 배치 규칙

### 6.1 Stateflow API 속성 기준

레이아웃 스크립트는 다음 API 속성을 명시적으로 다룬다. 논리 보존 열의 속성은 레이아웃
전후에 같아야 하며, 그래픽 열의 속성은 의도한 값이 설정되었는지 검사한다.

| 객체 | 그래픽 설계·검사 속성 | 변경하지 않고 비교할 논리 속성 |
| --- | --- | --- |
| `Stateflow.Chart` | `StateFont.Size`, `TransitionFont.Size`, 최종 `fitToView` | `ActionLanguage`, `Decomposition` |
| `Stateflow.State` | `Position`, `FontSize`, `BadIntersection` | `Name`, `LabelString`, 부모, `Decomposition`, `IsSubchart`, `ExecutionOrder` |
| `Stateflow.Transition` | `SourceOClock`, `DestinationOClock`, `MidPoint`, `LabelPosition`, `FontSize` | `Source`, `Destination`, `LabelString`, `ExecutionOrder` |
| `Stateflow.Data` | 해당 없음 | `Name`, `Scope`, `DataType`, `Port`, 초기값 |
| `Stateflow.Event` | 해당 없음 | `Name`, `Scope`, `Trigger` |

기본 전이는 Source가 없으므로 `SourceOClock`을 강제로 설정하지 않는다. 그 외의 전이는
Source와 Destination 포트, 경유점, 라벨 위치와 글꼴 크기를 레이아웃 명세에 포함한다.
모든 Transition 레이아웃 행에는 아래 분류 중 하나의 `RoutingType`을 반드시 기록한다.
라우팅 테이블의 최소 열은 객체 식별자, `RoutingType`, `SourceOClock`,
`DestinationOClock`, `MidPoint`, `LabelPosition`, `FontSize`다.

각 Transition에 대해 다음 그래픽 속성을 의도적으로 설정한다.

| 속성 | 용도 |
| --- | --- |
| `SourceOClock` | Source 경계의 출발 위치 |
| `DestinationOClock` | Destination 경계의 도착 위치 |
| `MidPoint` | 상태를 우회하는 전이 경로 |
| `LabelPosition` | 조건·액션 라벨의 독립 배치 |
| `FontSize` | 전이 라벨 글꼴 크기 |

`SourceOClock`, `DestinationOClock`, `MidPoint`는 서로 독립적인 값이 아니다. Stateflow는
한 속성을 바꾸면 곡선의 다른 접점 또는 경유점을 경계에 맞게 다시 계산할 수 있다. 따라서
이 프로젝트의 레이아웃 스크립트는 기본적으로 다음 순서를 사용한다.

1. `DestinationOClock`을 설정한다.
2. 평가 우선순위와 관련된 `SourceOClock`을 설정한다.
3. 상태 관통을 피하도록 `MidPoint`를 마지막에 설정한다.
4. 최종 `SourceEndpoint`, `MidPoint`, `DestinationEndpoint`를 다시 읽어 검사한다.

특정 전이에서 도착 포트가 우회 경로보다 더 중요한 경우에는 그 행을 명시적인
destination-port-priority 예외로 표시하고 `SourceOClock` 다음에 `DestinationOClock`을
설정한다. 어느 순서를 사용하더라도 요청 좌표만 신뢰하지 않고 실제 endpoint 간격과 경로를
검사한다. 실행 의미는 그래픽 위치에서 추론하지 않고 저장해 둔 `ExecutionOrder`와 outgoing
순서의 전후 비교로 보존한다.

### 6.2 RoutingType 분류와 경로 규칙

다음 한 문장을 모든 전이 라우팅의 기본 원칙으로 사용한다.

> **충돌 없는 최단 경로를 우선하고, 직선 → 한 번 꺾는 직각형 경로 → 외곽 통로 순으로 선택한다.**

Stateflow 일반 Transition은 한 개의 `MidPoint`를 기준으로 spline을 렌더링하므로 완전한
다중 구간 직교선을 직접 표현하지 못한다. 먼저 마주 보는 포트와 endpoint 평균
`MidPoint`로 직선을 만들고, 직선이 State를 관통할 때만 수평·수직 통로가 한 번 꺾이는
위치에 `MidPoint`를 둔다. 큰 원호, S자와 화면 바깥을 도는 경로는 최후 수단이다. 시각적인
꺾임만 만들기 위한 Junction 추가는 실행 의미를 바꾸므로 허용하지 않는다.

각 Transition은 레이아웃 테이블에서 다음 `RoutingType` 중 하나로 분류한다.

| RoutingType | 적용 대상 | OClock 원칙 | MidPoint와 경로 | 라벨 원칙 |
| --- | --- | --- | --- | --- |
| `AdjacentHorizontal` | 같은 행의 인접 State 간 단방향 전이 | 좌→우는 3→9, 우→좌는 9→3을 기본값으로 사용 | State 중심을 잇는 짧은 수평 직선 | 직선의 위쪽 빈 공간 |
| `AdjacentVertical` | 같은 열의 인접 State 간 단방향 전이 | 상→하는 6→12, 하→상은 12→6을 기본값으로 사용 | State 중심을 잇는 짧은 수직 직선 | 선의 좌우 중 더 넓은 빈 공간 |
| `Bidirectional` | 같은 State 쌍 사이에 양방향 전이가 존재 | 두 방향 모두 가장 가까운 별도 포트를 사용 | 주 방향은 직선, 반대 방향은 최소 오프셋의 짧은 단일-bend 경로. 큰 평행 곡선을 만들지 않음 | 두 경로의 서로 반대쪽 빈 공간 |
| `LongOuter` | 다른 State를 가로지르는 장거리 복귀·실패·중단 전이 | Source와 Destination에서 가장 가까운 차트 외곽을 향하는 포트 사용 | sibling State 묶음의 외곽 envelope에서 최소 40 px 떨어진 전용 외곽 lane 사용 | 외곽 lane의 가장 긴 빈 구간에 배치 |
| `SelfLoop` | Source와 Destination이 같은 전이 | 두 포트를 시계 눈금 기준 최소 2시간 간격으로 분리한다. 위쪽 loop는 11→1을 기본값으로 사용 | State 바깥쪽으로 부드럽게 부푼 loop를 만들고 다른 포트와 겹치지 않게 한다 | loop의 바깥쪽 꼭대기 또는 측면 |
| `Default` | Source가 없는 기본 전이 | `SourceOClock`은 설정하지 않고 Destination은 12시를 우선 사용 | 대상 State 바로 위에서 시작하는 짧은 경로 | 라벨이 있으면 대상 State 위쪽 빈 공간 |

OClock 기본값이 기존 포트 또는 평가 순서를 해치면 가장 가까운 빈 포트를 사용하되,
`ExecutionOrder`와 화면 전이 번호를 먼저 보존한다. 같은 State에서 출발하는 여러 전이의
실제 시작점은 최소 30 px 떨어뜨린다.

`LongOuter`의 첫 lane은 관련 sibling State 전체의 경계에서 최소 40 px 떨어져야 한다.
반대로 State envelope에서 180 px보다 멀리 보내지 않는다. 외곽 경로가 여러 개면 lane
중심선 사이에도 최소 40 px를 둔다. 부모 State 또는 Chart의 내부 여백이 부족하면 외곽
lane을 안쪽으로 압축하지 말고 별도의 State 배치 작업에서 부모 영역을 넓힌다.

`Bidirectional` 경로는 sibling State envelope 바깥으로 120 px보다 멀리 나가지 않고,
`SourceEndpoint–MidPoint–DestinationEndpoint` 길이를 Source–Destination 직선거리로 나눈
detour ratio가 2.20을 넘지 않게 한다. 이 상한이 과도한 큰 원호가 child State를 한쪽으로
몰아 보이게 만드는 문제를 방지한다.

공통 예외 State로 내려가는 전이가 여러 개이면 정상 State를 한 행에 두고 예외 State를
아래 행에 넓게 배치하는 구성을 먼저 검토한다. 정상 흐름을 여러 행으로 접어 cancellation
경로가 중간 정상 State를 가로지르게 만들지 않는다.

공통 예외 State의 폭은 표시 문자열에 필요한 크기로 제한한다. 여러 Source의 아래쪽 포트와
예외 State 위쪽 포트를 각각 좌우 순서대로 균등 분산하고, 직접선이 State를 관통하지 않으면
endpoint 평균을 `MidPoint`로 사용하는 대각선 직선을 허용한다. 모든 선을 수직으로 만들기
위해 예외 State를 확대하거나 같은 Destination 포트에 겹치지 않는다.

모든 `MidPoint`는 관계없는 State를 피해야 한다. 모든 `LabelPosition`은 State, 다른 라벨과
전이선이 없는 빈 공간에 직접 지정한다. Transition의 기본 `FontSize`는 9로 통일한다.

### 6.3 전이 우선순위와 화면 전이 번호 보존

`SourceOClock`을 바꾸면 암시적 순서를 사용하는 전이의 평가 순서가 바뀔 수 있다. 따라서
레이아웃을 보기 좋게 만드는 것보다 기존 실행 우선순위를 보존하는 것이 우선이다.

- 변경 전후 각 State의 outgoing Transition을 `ExecutionOrder` 순으로 수집해 같은 순서인지
  비교한다.
- 기존 `ExecutionOrder`와 그 값에서 파생되어 화면에 표시되는 전이 번호를 보존한다.
- Source와 Destination, `LabelString`을 변경하지 않는다.
- `LabelString`은 공백과 줄바꿈까지 정확히 비교한다. 레이아웃 작업에서 액션을 보기 좋게
  재서식하지 않는다.
- 포트 위치를 바꾼 뒤 순서가 달라졌다면 저장 전에 기존 `ExecutionOrder`를 명시적으로
  복원하고, 화면 전이 번호도 다시 비교한다.
- 실행 순서를 확실히 보존할 수 없는 포트 이동은 적용하지 않는다.

### 6.4 Junction 사용 제한

`Stateflow.Junction`은 전이선을 꺾기 위한 그래픽 waypoint가 아니라 실행 의미를 갖는 논리
객체다. `MidPoint`와 외곽 lane만으로 읽을 수 있는 경로를 만들 수 없는 경우의 마지막
수단으로만 사용한다.

- routing-only 작업에서는 Junction을 새로 만들거나 삭제하지 않는다.
- Junction이 꼭 필요하면 별도의 논리 변경 작업으로 분리한다.
- Junction 전후의 조건 평가, transition action, outgoing 순서, `ExecutionOrder`와 화면
  전이 번호가 동일함을 논리 서명과 회귀 시나리오로 증명한다.
- 의미 보존을 증명할 수 없으면 Junction을 추가하지 않고 남은 라우팅 한계로 보고한다.

### 6.5 routing-only 작업의 State 위치 불변 규칙

routing-only 작업은 Transition 경로와 라벨만 다루며 State 배치 작업과 혼합하지 않는다.

1. 작업 전에 모든 `Stateflow.State.Position`을 SSID와 계층 경로별로 저장한다.
2. `Auto Arrange`, State 이동, 크기 조절과 State label 재서식을 실행하지 않는다.
3. `SourceOClock`, `DestinationOClock`, `MidPoint`, `LabelPosition`, Transition
   `FontSize`와 라우팅 테이블만 수정한다.
4. 작업 후 모든 State의 `Position`을 기준선과 정확히 비교한다.
5. State 이동 없이는 기준을 만족할 수 없으면 현재 작업을 중단하고 별도 State 배치 작업을
   제안한다.

routing-only 작업의 허용 State `Position` 변경 건수는 **0건**이다.

### 6.6 Subviewer 좌표와 저장 후 재검증

Stateflow의 서브차트는 각 `Subviewer`마다 독립적인 그래픽 좌표계를 사용한다. 따라서
상위 차트 좌표와 서브차트 좌표를 한 좌표계처럼 계산하지 않는다.

1. 차트, 직접 자식 객체가 있는 Composite State와 모든 Subchart를 재귀적으로 수집하고
   가장 깊은 scope부터 처리한다.
2. State와 Transition을 `Subviewer`별 scope로 묶는다. 부모 차트에서 보이는 Subchart
   State의 `Position`을 그 내부 편집 화면의 정렬 영역으로 사용하지 않는다.
3. Subchart의 직접 자식 State bounding box는 로컬 `minX=80..120`, `minY=100..200`에
   둔다. 일반 시작점은 `[100 120]`이며, 위쪽 복귀 lane의 저장 안정성을 위해 필요한
   scope만 `y=200`까지 허용한다. 부모 Chart의 Subchart `Position`이나 현재 편집 카메라
   `subviewS.pos`를 State 정렬 영역으로 사용하지 않는다.
4. routing-only 작업에서는 각 scope의 현재 State 좌표와 표준 좌표 사이의 공통 평행이동
   offset을 계산하고, Transition의 `MidPoint`와 `LabelPosition`에만 같은 offset을 적용한다.
5. 같은 scope 안의 State 크기가 표준과 다르거나 State별 offset이 서로 다르면 자동 변환을
   중단한다.
6. State 배치가 끝난 scope마다 즉시 Transition endpoint, midpoint와 label을 새로 계산한다.
   전체 State를 먼저 이동한 뒤 모든 Transition을 한꺼번에 처리하지 않는다.
7. 배치 직후의 메모리 상태만 믿지 않고 모델을 저장한 뒤 닫고 다시 열어 State 위치,
   Transition geometry, 논리 서명을 다시 비교한다.
8. 저장 또는 재열기 검증이 실패하면 작업 전 백업본으로 복구한다.
9. 모든 scope의 검증이 끝난 뒤 서브차트별로 `view`와 `fitToView`를 적용하고, 마지막에
   상위 Chart를 연다. 이 화면 작업으로 모델의 dirty 상태가 바뀌지 않아야 한다.
10. 동일 후보에 레이아웃을 두 번 연속 실행해 두 번째 State `Position`, endpoint,
    `MidPoint`, `LabelPosition` 변화가 허용 오차 내 0인지 확인한다.

각 Subviewer에서 State bounding box가 전체 그래픽 bounding box에서 차지하는 면적 비율은
최소 0.50이어야 한다. 그래픽 bounding box가 State envelope의 왼쪽·오른쪽·위·아래로
확장되는 크기는 각 방향 최대 180 px로 제한한다. 이 검사는 `fitToView`와 별개이며 저장 후
다시 읽은 실제 endpoint, midpoint와 label 좌표로 계산한다.
Subchart의 `StateMinX/StateMinY`가 위 로컬 범위를 벗어나면 hard layout-quality 위반이다.
`subviewS.pos`는 State 배치 영역이 아니라 Space/Fit이 맞추는 저장 페이지다. State와
Transition 배치가 확정된 뒤 페이지는 전체 graphical bounding box를 기준으로 가로 활용률
0.90, 세로 활용률 0.82, 방향별 최소 여백 60 px가 되도록 별도로 정규화한다. R2025b에서
이 페이지 rectangle은 공개 API로 쓰기 불가능하므로, 모델을 닫은 상태에서 SLX Stateflow
XML의 해당 Subchart `subviewS.pos`만 변경할 수 있다. 이때 후보 백업, SSID별 단일 매치,
State/Transition/Junction 수, 전체 논리 서명과 전체 객체 geometry의 무변경을 저장·재열기로
검증해야 한다. 다른 `subviewS` 값이나 논리 XML은 수정하지 않는다.

## 7. 폰트와 화면 표시

- Chart의 기본 State 글꼴 크기는 10으로 설정한다.
- Chart의 기본 Transition 글꼴 크기는 9로 설정한다.
- 개별 객체의 글꼴도 같은 기준을 따르되, 텍스트를 맞추기 위해 축소하지 않는다.
- 모든 객체 배치와 검증을 마친 뒤 차트를 열고 `fitToView`를 실행한다.
- `fitToView`는 최종 화면 맞춤과 육안 검토에만 사용하며 객체 배치를 대신하지 않는다.
- 저장된 pan/zoom만 크게 설정해 과대 페이지를 숨기지 않는다. 저장·닫기·재열기 후 실제
  Space/Fit 동작과 같은 `view(subchart); fitToView(subchart)`를 다시 실행해 검사한다.
- 먼저 `view(subchart)`로 내부 편집 화면을 활성화한 다음 같은 Subchart 객체에
  `fitToView(subchart)`를 호출한다. 내부 자식 State 하나에 `fitToView`를 호출하면 그 State만
  화면에 가득 차도록 과도하게 확대될 수 있다.
- 저장된 Subchart 페이지가 콘텐츠보다 현저히 크면 ZoomFactor를 추가 확대하지 말고 먼저
  페이지 rectangle을 graphical bounding box에 맞게 정상화한다. 화면 맞춤 후 임의의 추가
  확대 없이도 읽기 좋아야 한다.
- 추가 확대 후 어느 한 화면 축의 콘텐츠 점유율은 최소 0.70이어야 하고, 가로 0.93 또는
  세로 0.78을 넘겨 잘려서는 안 된다. 확대율을 저장하고 모델을 닫았다가 다시 열어 각
  Subchart의 `ZoomFactor`가 유지되는지 검사한다.
- 절대 표시 픽셀은 Stateflow 창 크기와 도킹 상태에 따라 달라지므로 hard 기준으로 쓰지
  않는다. 저장·재열기와 실제 Space/Fit 후 `max(graphicWidth/pageWidth,
  graphicHeight/pageHeight)`가 0.70 이상이어야 한다. 가로 활용률은 0.93, 세로 활용률은
  0.82를 넘지 않아야 하며 그래픽이 페이지 밖으로 나가면 안 된다. 이 검사는 후보 파일명뿐
  아니라 사용자가 실제로 여는 정식 모델에도 항상 적용한다.
- `sfprint(..., wholeChart=true)`는 서브차트 객체 경계보다 큰 편집 작업면을 포함할 수 있다.
  이 PNG의 빈 배경만으로 child State 쏠림을 판정하지 않고, 저장 후 좌표 기반 canvas 지표와
  실제 편집기 `fitToView` 화면을 함께 검토한다.

## 8. 반복 배치 절차

한 번의 좌표 지정으로 완료하지 않고 다음 순서를 반복한다.

1. State 크기와 위치 배치
2. Transition 시작점과 도착점 배치
3. `MidPoint`를 사용한 전이 통로 배치
4. Transition 라벨 배치
5. 자동 겹침·교차 검사
6. 차트를 열어 육안으로 확인
7. 좌표 미세 조정

`Auto Arrange`를 사용했다면 그 결과는 1단계의 초안으로만 취급한다.

## 9. 자동화 실행 순서

새 차트와 기존 차트 변경은 다음 순서로 실행한다.

1. 레이아웃 스크립트를 백업 활성 상태로 실행한다.
2. `amr.stateflow.inspectGraphicalLayout(model, chart)`를 실행하고
   `HardViolationCount == 0`, `ExactRoutingViolationCount == 0`인지 확인한다.
3. `tests/unit/StateflowGraphicalLayoutTest.m`에서 해당 차트의 테스트를 실행한다.
4. 모델 Update Diagram과 `model_check`를 실행한다.
5. 기능 단위검사와 시나리오 회귀를 실행한다.
6. 차트를 열고 마지막으로 `fitToView`를 적용한 화면을 육안 확인한다.

레이아웃 스크립트, 검사기 또는 테스트 중 하나라도 없거나 실패하면 새 차트는 완료되지 않은
것으로 기록한다. 자동 검사기가 판정하지 못하는 전이선 관통이나 텍스트 잘림은 성공으로
간주하지 않고 육안 검토 항목으로 남긴다.

## 10. 검증 기준

### 10.1 그래픽 검증

다음 항목이 모두 0건 또는 참이어야 한다.

- 모든 State의 `BadIntersection == false`
- State와 State 사이의 겹침 0건
- State와 Transition 라벨 사이의 겹침 0건
- Transition 라벨끼리의 겹침 0건
- Transition 라벨과 관계없는 전이선 사이의 겹침 0건
- 전이선이 관계없는 State 내부를 통과하는 경우 0건
- 미분류 Transition 또는 `RoutingType` 누락 0건
- `AdjacentHorizontal`·`AdjacentVertical` 정상 진행이 직선이 아닌 경우 0건
- 정상 진행 직선과 반대 방향 곡선이 겹치는 양방향 경로 0건
- `LongOuter` lane의 40 px 여백 위반 0건
- `LongOuter` lane의 180 px 최대 이격 위반 0건
- Subviewer State bounding-box 활용률 0.50 미만 0건
- State envelope 방향별 canvas 확장 180 px 초과 0건
- `Bidirectional` envelope 이탈 120 px 또는 detour ratio 2.20 초과 0건
- `SelfLoop`의 Source/Destination 포트 2시간 간격 위반 0건
- routing-only 작업의 State `Position` 변경 0건
- 의미 보존 검증 없이 추가하거나 삭제한 Junction 0건
- State 경계 밖으로 잘리는 이름 또는 액션 0건
- 기본 전이가 불필요하게 긴 경우 0건

공통 검사기는 모든 발견된 Subviewer에 대해 직접 자식 State/Transition/Junction 수,
State·전체 그래픽 bounding box, 로컬 offset, 중심 차이, 방향별 canvas 확장,
route length ratio와 maximum route deviation을 `HierarchyInventory`에 기록한다. 또한
과대 State, Subchart canvas 중심 오차 10% 초과, State envelope보다 한 방향으로 100 px 이상
확장된 Transition canvas, 다른 State와 sibling path를 모두 피하는 직선 기회,
State/graphics 중심 차이 20% 초과를 layout-quality 항목으로 검사한다.

공통 검사기는 sibling State 겹침, `BadIntersection`, NavigationRegion의 정상·예외 행 순서,
수평 80 px·수직 110 px 간격, State/Transition의 10/9 글꼴, Transition 라벨과 State 또는
다른 라벨의 겹침, Source–MidPoint–Destination 근사 경로의 관계없는 State 관통, 동일
Source 전이 시작점의 30 px 간격을 hard violation으로 보고한다.

State 내부 텍스트가 경계 안에 들어가는지는 렌더러와 화면 환경에 따른 오차가 있으므로
advisory와 육안 검토를 함께 사용한다. advisory가 있다는 사실을 숨기지 않고 각 항목을
검토해 상태 확대 또는 라벨 정렬이 필요한지 결정한다.

R2025b의 State 글꼴 10 렌더링을 기준으로 텍스트 폭 advisory는 문자당
`0.47 × FontSize`와 수평 padding 18 px를 사용한다. 이 값은 실제 렌더링 경계 검토를
대신하지 않으며 MATLAB 릴리스나 글꼴이 바뀌면 다시 교정한다.

자동 검사만으로 전이선과 텍스트의 실제 가독성을 완전히 판정하지 않는다. 최종 차트를 열어
정상 상단·예외 하단 구분, 읽기 방향, 라벨 간격을 육안으로 확인한다.

Stateflow API는 렌더링된 spline 자체를 제공하지 않으므로 path–path 검사는 endpoint와 한
midpoint를 잇는 두 선분으로 보수적으로 근사한다. 근사 경고는 자동 성공으로 숨기지 않는다.
0건으로 줄이지 못한 경우에는 오직 path–path 항목만 예외 검토할 수 있으며, 해당 Transition
SSID 쌍, 이유와 최종 화면을 테스트와 결과 노트에 고정한다. State 관통, label–State,
label–label, label–path와 exact routing 경고는 이 예외를 적용하지 않고 반드시 0건이어야 한다.

### 10.2 논리 동등성 검증

레이아웃 전후 논리 서명을 객체별로 비교한다.

- State 이름, 액션과 계층 관계 동일
- Transition Source와 Destination 동일
- Transition 조건·액션 `LabelString` 동일
- 각 State의 outgoing Transition 순서 동일
- State와 Transition의 `ExecutionOrder` 및 화면 전이 번호 동일
- Data와 Event 정의 동일

새 차트를 만드는 경우에는 레이아웃 단계 직전의 논리 구현본을 기준선으로 사용한다.

### 10.3 실행 검증

- 모델 Update Diagram을 실행하고 오류가 없어야 한다.
- `model_check` 구조 검사를 실행한다.
- 관련 MATLAB 단위검사와 시나리오 시뮬레이션을 다시 실행한다.
- 레이아웃 전후의 관측 가능한 결과가 같아야 한다.
- Simulink Test가 설치되어 있지 않으므로 `model_test`는 사용하지 않는다.

## 11. 작업 결과 기록 형식

작업을 마치면 모델별 결과 문서 또는 실험 노트에 다음 표를 남긴다.

### State 변경표

| 계층 경로 | 변경 전 Position | 변경 후 Position | FontSize | 비고 |
| --- | --- | --- | ---: | --- |
| 예: `Operational/NavigationRegion/NavIdle` | `[x y w h]` | `[70 90 230 120]` | 10 | 정상 흐름 상단 |

### Transition 배치표

| Source → Destination | RoutingType | SourceOClock | DestinationOClock | MidPoint | LabelPosition | 실행 순서 보존 |
| --- | --- | ---: | ---: | --- | --- | --- |
| 예: `NavIdle → Planning` | `AdjacentHorizontal` | 값 | 값 | `[x y]` | `[x y w h]` | PASS |

### 검증 결과표

| 검증 | 결과 | 증거 |
| --- | --- | --- |
| 논리 서명 비교 | PASS/FAIL | 비교 결과 파일 또는 명령 |
| 그래픽 겹침 검사 | PASS/FAIL | 검사 건수 |
| Update Diagram | PASS/FAIL | 실행 결과 |
| 회귀 시나리오 | PASS/FAIL | 실행한 스크립트와 결과 |
| 최종 육안 확인 | PASS/FAIL | 확인한 차트와 남은 한계 |

남아 있는 교차나 가독성 한계가 있으면 완료로 숨기지 않고 위치와 이유를 명시한다.
