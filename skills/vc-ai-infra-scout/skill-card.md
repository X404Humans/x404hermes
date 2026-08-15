## Description: <br>
Helps VC agents scout AI-infrastructure startups by combining live market, founder, and fundraising signals into a ranked shortlist with source links and an outreach note. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[selat-dev](https://clawhub.ai/user/selat-dev) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
VC investors and deal-sourcing agents use this skill to find AI-infrastructure companies and founders, compare live market and fundraising signals, and prepare a concise ranked outreach shortlist. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The workflow depends on an external npm CLI and paid third-party API calls funded from the user's Circle wallet. <br>
Mitigation: Run the free verification step first, review quoted prices, and proceed only after the user approves the cost, data sources, and wallet setup. <br>
Risk: A paid run could spend funds if started before the user understands the live quotes and wallet requirements. <br>
Mitigation: Use the documented dry-run flow before wallet setup and rely on the per-step caps and $0.40 full-run cap. <br>
Risk: Wallet setup could expose sensitive credentials if handled outside the intended CLI flow. <br>
Mitigation: Do not request, paste, or handle private keys; use the CLI's Circle wallet integration and keep funds in the user's wallet. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/selat-dev/skills/vc-ai-infra-scout) <br>
- [Skill homepage](https://github.com/SELAT-AI/selat-skills/tree/main/skills/vc-ai-infra-scout) <br>
- [SELAT skills documentation](https://github.com/SELAT-AI/selat-skills) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Markdown, Shell commands, Guidance] <br>
**Output Format:** [Markdown with inline shell commands and ranked deal-shortlist guidance] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Uses paid SELAT API calls with dry-run price review and a $0.40 full-run cap.] <br>

## Skill Version(s): <br>
1.0.0 (source: frontmatter and server release evidence) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
