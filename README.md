# autelon/.github

Autelon 조직의 공용 설정 저장소다.

| 경로 | 역할 |
|---|---|
| `profile/README.md` | 조직 페이지(github.com/autelon) 첫 화면 |
| `.github/pull_request_template.md` | 자체 PR 템플릿이 없는 조직 저장소의 기본 PR 템플릿 |
| `.github/workflows/git-policy.yml` | 재사용 워크플로. PR 에 merge 커밋이 있으면 실패한다 |
| `rulesets/main.json` | main 보호 규칙의 표준 |
| `scripts/setup-repo.sh` | 저장소 설정과 main ruleset 을 적용하고 결과를 다시 읽어 보여 준다 |

## 왜 스크립트인가

조직 단위 ruleset 은 GitHub Team 플랜부터 쓸 수 있다(Free 조직에서 `GET /orgs/autelon/rulesets` 가 "Upgrade to GitHub Team" 으로 거절된다).
그래서 표준을 이 저장소에 두고, 저장소마다 스크립트로 같은 값을 적용한다.

## 새 저장소에 적용하기

1. 저장소 CI 에 필수 검사 job(관례: `check`)을 만들고, 트리거에 `pull_request` 와 `merge_group` 을 넣는다.
2. 같은 워크플로에 git 규칙 검사를 붙인다.
   ```yaml
   jobs:
     git-policy:
       uses: autelon/.github/.github/workflows/git-policy.yml@main
   ```
3. 표준을 적용한다. 필수 검사 이름을 모두 넘긴다.
   ```
   scripts/setup-repo.sh autelon/<repo> check "git-policy / merge-commits"
   ```

필수 검사는 그 이름의 검사가 한 번 이상 실행된 뒤에 걸어야 PR 이 영원히 대기하는 일을 피할 수 있다. 처음에는 CI 를 main 에 먼저 올리고 나서 스크립트를 돌린다.

## 표준이 정하는 것

- main: 삭제·force push 금지, PR 필수(승인 0), 필수 검사, 병합 방식은 merge commit 하나.
- public 저장소는 머지 큐를 쓴다. 큐가 최신 main 과 합친 결과로 검사를 다시 돌린 뒤 병합한다.
- private 저장소는 Free 조직에서 머지 큐를 못 쓰므로 "up to date 필수"로 대신한다.
- 저장소 설정: merge commit 만 허용, auto-merge 허용, Update branch 버튼, 병합 후 브랜치 자동 삭제, merge commit 메시지는 PR 제목과 본문.
- 작업 브랜치는 rebase 로만 최신화한다. CI(`git-policy`)가 PR 의 merge 커밋을 막는다.
