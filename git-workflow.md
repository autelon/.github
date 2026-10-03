# Git 브랜치·병합 표준 (모든 프로젝트 공통)

이 문서가 모든 프로젝트의 브랜치 전략과 GitHub 저장소 설정의 기준이다.
적용과 확인은 각 프로젝트를 진행하는 세션이 한다. 기준을 바꿀 때는 이 파일을 먼저 고치고, 프로젝트마다 반영 여부를 확인한다.
프로젝트가 의도적으로 다르게 가는 부분은 그 프로젝트 문서(예: `docs/git-rules.md`)에 이유와 함께 적는다.

## 원칙

- **main 은 배포 버전이다. 지켜야 하는 건 main 하나다.** 작업 브랜치는 rebase·force push 를 자유롭게 한다.
- **main 에 들어가는 변경은 최신 main 위에서 검사를 통과한 것이어야 한다.**
- 작업 브랜치를 최신화할 때는 **rebase 만 쓴다.** main 을 작업 브랜치로 merge 하지 않는다.

## main 보호 (GitHub Ruleset, 대상: 기본 브랜치)

- 삭제 금지, force push 금지(non-fast-forward)
- PR 필수. GitHub 필수 승인 수는 0 이다(계정이 하나라 승인 기능을 못 쓴다). 리뷰는 아래 PR 절차대로 에이전트나 사람이 하고 결과는 코멘트로 남긴다.
- 필수 상태 검사: 프로젝트 CI job(관례: `check`)과 조직 공용 `git-policy / merge-commits` 두 개.
- 최신화 보장은 둘 중 하나로 한다.
  - **머지 큐를 쓸 수 있으면 머지 큐를 쓴다.** 조직 소유의 public 저장소면 무료 조직이어도 쓸 수 있다. private 저장소는 Enterprise Cloud 조직이어야 한다. 개인 계정 저장소에서는 쓸 수 없다.
  - 못 쓰면 "Require branches to be up to date before merging"(ruleset 의 `strict_required_status_checks_policy: true`)를 켠다.
- 병합 방식은 프로젝트마다 하나로 정한다. 기본값은 merge commit 이다(브랜치 커밋이 그대로 남고, PR 마다 merge commit 하나).

### 머지 큐의 동작 (GitHub docs 확인, autelon/.github PR #1·#2 로 실제 확인)

- PR 을 큐에 넣으면 큐가 임시 브랜치(`gh-readonly-queue/main/pr-N-…`)를 만든다. 내용은 최신 main + 큐에서 앞선 PR 들 + 이 PR 을 설정한 병합 방식으로 합친 것이다.
- 그 임시 브랜치에서 필수 검사가 `merge_group` 이벤트로 다시 돈다. 통과하면 main 에 반영한다.
- 작업 브랜치 자체는 rebase 하지 않는다. 최신 base 와 합친 결과를 큐가 따로 만들어 검사한다. 충돌이 날 때만 작업 브랜치를 rebase 해서 다시 올린다.
- CI 에 `merge_group:` 트리거가 꼭 있어야 한다. 없으면 큐가 검사 결과를 기다리다 실패한다.
  - `pull_request` 이벤트 값(`github.event.pull_request.*`)을 쓰는 단계는 merge_group 실행에서 건너뛰거나, `github.event.merge_group.base_sha` / `head_sha` 를 쓰게 고친다.

## 저장소 설정

- `delete_branch_on_merge: true`. 병합된 브랜치는 자동으로 지운다. 원격 브랜치를 손으로 지우지 않는다.
- `allow_auto_merge: true`
- `allow_update_branch: true`. PR 화면에 "Update branch" 버튼이 생긴다. 이 버튼은 작업 브랜치를 갱신하고 main 은 건드리지 않는다. 쓸 때는 rebase 옵션을 고른다.
- 병합 방식은 정한 하나만 허용한다.
- 이 설정은 GitHub 에만 있다. 프로젝트 문서에는 현재 값을 확인하는 방법을 적는다: `gh api repos/{owner}/{repo}`, `gh api repos/{owner}/{repo}/rulesets`.

## CI 가 강제하는 것

- 프로젝트 필수 검사 job(`check`)은 빌드·테스트를 돌린다. 커밋 메시지 형식 검사가 있으면 같은 job 에서 `pull_request` 일 때만 돌린다.
- **PR 범위(`base..head`)에 merge 커밋이 있으면 실패**하는 검사는 조직 공용 재사용 워크플로 `autelon/.github/.github/workflows/git-policy.yml@main` 이 한다(필수 검사 이름 `git-policy / merge-commits`). main 을 merge 로 끌어온 브랜치가 들어오는 걸 막는다.
- 이 두 검사는 PR 단계에서만 실제로 검사하고, 머지 큐(`merge_group`) 실행에서는 통과로 처리한다. 큐 단계에서 의미 있는 검사는 빌드·테스트다.

## 에이전트의 PR 절차

1. 작업 브랜치에서 커밋한다. PR 전에 커밋을 정리해 둔다.
2. **PR 을 올릴 때 바로 머지하지 않는다.** 작업자와 다른 에이전트나 사람이 리뷰하고, **그 리뷰어가 auto-merge 를 켜거나 머지한다.**
   - 리뷰어와 작업자는 메인 에이전트와 서브에이전트 관계일 수 있다. 누가 리뷰어인지는 프로젝트 문서에 정한다.
   - 사용자가 "이 PR 은 내가 리뷰한다"고 하면 리뷰어는 사용자다. 에이전트는 그 PR 의 머지 명령을 내지 않는다.
   - 모든 커밋이 사용자 계정 하나로 올라가서 GitHub 의 PR 승인(approve)은 쓸 수 없다. 자기 PR 은 승인할 수 없기 때문이다. 리뷰 결과는 PR 코멘트로 남긴다.
3. 리뷰어의 머지 명령:
   - 머지 큐가 있는 저장소: `gh pr merge <PR>`. 필수 검사가 아직 진행 중이면 auto-merge 가 켜지고, 이미 통과했으면 큐에 들어간다(gh 도움말 기준).
   - 머지 큐가 없는 저장소: `gh pr merge <PR> --auto --<병합 방식>`.
   - `--match-head-commit <리뷰한 head sha>` 를 붙인다. 리뷰 뒤에 브랜치가 바뀌었으면 머지되지 않는다. 이 검사는 GitHub 승인과 무관하게 sha 만 비교해서, 계정이 하나여도 동작한다.
     - gh 소스(pkg/cmd/pr/merge/http.go)에서 확인함: 바로 머지와 auto-merge·큐 등록 경로 모두 `expectedHeadOid` 로 넘긴다.
   - `--admin`(큐와 검사 우회)은 쓰지 않는다.
4. PR 이 main 보다 뒤처져서 막히거나 충돌이 나면 rebase 해서 다시 올린다.
   ```
   git fetch origin
   git rebase origin/main
   git push --force-with-lease
   ```
   그다음 검사가 다시 통과하는지 확인한다. `--force` 는 쓰지 않는다.
5. 작업 브랜치를 다른 세션·에이전트와 같이 쓰고 있었다면, rebase 뒤 상대 쪽은 `git pull --rebase` 나 `git reset --hard origin/<branch>` 로 맞춰야 한다. 그 사실을 보고에 적는다.

## 새 프로젝트를 시작할 때

1. 저장소는 **`autelon` 조직**(github.com/autelon, Free 플랜)에 만든다. 사용자가 Claude 와 만드는 모든 프로젝트가 이 조직에 들어간다. 머지 큐를 쓰려면 public 이어야 한다(Free 조직의 private 저장소는 머지 큐 불가). private 이 필요하면 머지 큐 대신 "up to date" 규칙을 쓰고, 그 사실을 사용자에게 알린다.
2. 저장소 설정과 main ruleset 은 **`autelon/.github` 의 `scripts/setup-repo.sh`** 로 적용한다. 표준 값은 그 저장소의 `rulesets/main.json` 과 스크립트가 원본이다. 조직 단위 ruleset 은 Free 플랜에서 못 쓴다(API 가 "Upgrade to GitHub Team" 으로 거절).
   - 표준과 다른 값을 쓰거나 기존 저장소 설정을 바꿀 때는 바꿀 값을 사용자에게 보여 주고 승인을 받는다.
   - 필수 검사는 그 이름의 검사가 한 번 돈 뒤에 건다. CI 를 main 에 먼저 올리고 스크립트를 돌린다.
   - git 규칙 검사는 재사용 워크플로를 부른다: `uses: autelon/.github/.github/workflows/git-policy.yml@main` → 필수 검사 이름 `git-policy / merge-commits`.
3. CI 필수 검사 job 을 만든다: `pull_request` + `merge_group`(머지 큐를 쓸 때) + `push: main` 트리거.
4. 프로젝트 문서(`docs/git-rules.md` 등)에 이 표준을 따른다는 것과 프로젝트별 차이(병합 방식, 필수 검사 이름)를 적는다.
5. 적용 뒤 `gh api` 로 실제 값을 다시 읽어 확인한다.

## 기존 프로젝트를 점검할 때

- `gh api` 로 저장소 설정과 ruleset 을 읽어 이 문서와 비교한다. 다른 점은 고치기 전에 사용자에게 보고한다.
- 다른 세션이 작업 중인 프로젝트는 사용자가 허락하기 전에는 설정을 바꾸지 않는다.
