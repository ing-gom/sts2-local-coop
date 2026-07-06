# STS2 로컬 협동 (Sts2SoloCoop)

**슬레이 더 스파이어 2 협동을 혼자** — 두 캐릭터를 한 사람이, 한 화면에서 조작.

> English: [README.md](README.md)

STS2 협동은 네트워크 락스텝(플레이어=네트워크 피어)이라, 한 프로세스에서 "핫시트"로 두 캐릭터를
돌리는 건 비현실적이에요 — 선택 지점마다 있는 ~10개의 동기화기가 각각 모든 플레이어의 네트워크
투표를 기다립니다. 그래서 이 프로젝트는 **게임 인스턴스 2개를 실제로 띄우고**(둘 다 진짜 피어라
게임이 의도대로 동작) 그 둘을 한 곳에서 조작하게 해줍니다: 두 창을 한 컨테이너에 담는
런처/임베더 + 진단용 소형 모드.

연결은 게임 **내장 플래그 `--fastmp`**를 씁니다 — 정식 멀티플레이 메뉴가 `127.0.0.1` ENet으로
호스트/조인하게 만들어, Steam 친구도 개발자 콘솔도 필요 없어요.

## 다운로드 & 설치
**[Releases](https://github.com/ing-gom/sts2-local-coop/releases)**에서 패키지
(`sts2-local-coop-vX.Y.Z.zip`)를 받은 뒤:
1. `Sts2SoloCoop/` 폴더를 게임 mods 폴더에 복사:
   `…/Steam/steamapps/common/Slay the Spire 2/mods/Sts2SoloCoop/`
   (→ `mods/Sts2SoloCoop/Sts2SoloCoop.dll`·`Sts2SoloCoop.json`·`Sts2.ModKit.dll`)
2. `tools/` 폴더는 편한 곳에 두고 — 이걸 실행합니다.
3. 인게임 모드 목록에서 **Sts2SoloCoop** 활성화(선택 — 도구+`--fastmp`만으로도 동작).

> 소스 빌드: 이 repo 클론 후 `dotnet build -c Release` ([빌드](#빌드) 참고).

## 빠른 시작
1. 게임을 **창(Windowed) 모드**로 (설정 → 비디오). Steam은 켜두기.
2. 이 저장소의 `tools/` 폴더에서 PowerShell:
   ```powershell
   ./coop-embed.ps1
   ```
   → 두 인스턴스를 `--fastmp`로 띄우고 한 창 안에 좌우로 편입(호스트=왼쪽/클라=오른쪽 자동정렬,
   컨테이너 닫으면 둘 다 종료). 데스크톱에 따로 띄우려면 `./coop-launch.ps1`(타일링).
3. 각 패널에서 게임 **Multiplayer** 메뉴 사용: 왼쪽 → **Host**, 오른쪽 → **Join**
   (자동으로 `127.0.0.1` 접속). 캐릭터 선택 → Ready → 시작.
4. **양쪽 조작:** 포커스된 패널/창이 입력을 받음. 패널 클릭(또는 `tools/coop-control.ahk`로
   `F1`/`F2` 원키 전환).

## 협동은 공유 투표
파티가 함께 이동해요: **맵·이벤트·보상**은 **모든 플레이어가 선택해야** 진행되는 공유 투표입니다.
그러니 그 지점에선 **양쪽 패널에서** 조작하세요(예: 이동하려면 왼쪽·오른쪽 패널에서 각각 다음 맵
노드 클릭). 전투는 각자 캐릭터라 각 패널에서. 정상 동작이며 입력 멈춤이 아니에요.

## 모드 (선택적 보조)
`Sts2SoloCoop.dll`은 인게임 개발 편의(콘솔 커맨드 + 로비 패치 1개)를 더합니다. 플레이에 **필수는
아니고**(`--fastmp` + 도구면 충분), 테스트에 유용:
- `sc_probe` — 넷 타입·플레이어·NetId·로컬 관점 덤프
- `sc_swap <netid>` — `LocalContext.NetId` 전환(잘못된 id 방지 가드)
- `AllowSoloBegin` 패치 — 1인 호스트가 멀티 타입 런을 시작하게 허용(솔로 스모크용)

## 빌드
표준 STS2(Godot 4.5 / .NET) 모드. DLL을 빌드해 `Sts2SoloCoop.json`과 함께 게임의
`mods/Sts2SoloCoop/` 폴더에 넣으세요:
```
dotnet build -c Release
```
(공용 `Sts2.ModKit` 빌드 props 사용 — 레이아웃이 다르면 import 조정.)

## 문제 해결
- **PS 스크립트가 안 돌아감**("스크립트를 로드할 수 없습니다") → `powershell -ExecutionPolicy Bypass -File .\coop-embed.ps1`
- **창이 리사이즈/타일/임베드 안 됨** → 게임을 **창(Windowed) 모드**로 (전체화면은 창 배치 무시).
- **멀티 메뉴가 계속 Steam 친구를 요구** → 두 인스턴스 다 **`--fastmp`로 실행**해야 함(스크립트가
  처리; Steam 실행분은 미적용). fastmp에선 Join이 `127.0.0.1`에 자동 접속하고 친구 목록이 안 뜨는 게 정상.
- **다음 맵 노드 클릭이 안 먹힘** → co-op 공유 투표라 **양쪽 창**에서 클릭.
- **임베드 패널이 검거나/멈추거나/떨림** → GPU 게임 임베드는 불안정할 수 있음. 컨테이너를 닫고
  (둘 다 종료됨) `coop-launch.ps1`(데스크톱 타일링)으로.

## 참고
- Windows 전용(도구가 Win32 창 API + `--fastmp` 사용).
- 컨테이너 임베드(`coop-embed.ps1`)는 되지만 GPU 게임 특성상 다소 불안정할 수 있어요. 패널이
  이상하면 `coop-launch.ps1`(타일링)으로.
- Mega Crit과 무관. Slay the Spire 2 기반.

MIT 라이선스 — [LICENSE](LICENSE) 참고.
