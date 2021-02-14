# learning-terraform-github-actions
A POC to do ChatOps for Terraform in GitHub Actions

## User Story
As a DevOps engineer I want to see the terraform plan and apply in the pull request. 
I would like automation to run this so that developers (like me) never have access to the secrets. 
The terraform apply should run the plan outfile. 

## Demonstration
This is merely a POC but see this PR [#8](https://github.com/sblack4/learning-terraform-github-actions/pull/8)

## Artifact
The output of this is the [terraform workflow file](https://github.com/sblack4/learning-terraform-github-actions/blob/main/.github/workflows/terraform.yaml). Some of it was cropped from work done by hashicorp, which is plainly obvious if you've seen their work. Unfortunately their work did not fulfill the last acceptance criteria. 

Here's the relevant piece of that file:

```yaml

---
on:
  issue_comment:
  pull_request:
  pull_request_review_comment:
  
jobs:
  plan_or_apply:
    runs-on: ubuntu-latest
    name: Terraform Plan or Apply
    steps:

      - uses: actions/checkout@v2

      # I know this is like so 2000 and late
      # but you can use the version you want
      - uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: 0.12.25
      
      - name: Terraform fmt
        id: fmt
        run: terraform fmt -check
        continue-on-error: true
      
      - name: Terraform Init
        id: init
        run: terraform init
      
      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color
      
      - name: Terraform Plan
        continue-on-error: true
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform plan')
        id: plan
        run: terraform plan -no-color -out plan.out

      - name: 'Upload Artifact'
        continue-on-error: true
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform plan')
        uses: actions/upload-artifact@v2
        with:
          name: terraform-plan-artifact
          path: plan.out
          retention-days: 5

      - uses: actions/github-script@0.9.0
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform plan')
        env:
          PLAN: "terraform\n${{ steps.plan.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = `#### Terraform Format and Style 🖌\`${{ steps.fmt.outcome }}\`
            #### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
            #### Terraform Validation 🤖${{ steps.validate.outputs.stdout }}
            #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`
            <details><summary>Show Plan</summary>
            \`\`\`${process.env.PLAN}\`\`\`
            </details>
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`, Workflow: \`${{ github.workflow }}\`*`;
            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
            
      # why this action?
      # see https://github.com/actions/toolkit/issues/501
      - name: Download a single artifact
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform apply')
        uses: dawidd6/action-download-artifact@v2
        with:
          name: terraform-plan-artifact
          github_token: ${{secrets.GITHUB_TOKEN}}
          workflow: terraform.yaml
          workflow_conclusion: success
      
      - name: Terraform Apply
        id: apply
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform apply')
        run: terraform apply -no-color "plan.out" 

      - uses: actions/github-script@0.9.0
        if: github.event_name == 'issue_comment' && contains(github.event.comment.body, 'terraform apply')
        env:
          apply: "terraform\n${{ steps.apply.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = `#### Terraform Format and Style 🖌\`${{ steps.fmt.outcome }}\`
            #### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
            #### Terraform Validation 🤖${{ steps.validate.outputs.stdout }}
            #### Terraform apply 📖\`${{ steps.apply.outcome }}\`
            <details><summary>Show apply</summary>
            \`\`\`${process.env.apply}\`\`\`
            </details>
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`, Workflow: \`${{ github.workflow }}\`*`;
            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
```

## References
- https://github.com/hashicorp/setup-terraform
- https://docs.github.com/en/actions/guides/storing-workflow-data-as-artifacts
- https://docs.github.com/en/actions/reference/events-that-trigger-workflows#issue_comment
- https://github.com/actions/toolkit/issues/501
