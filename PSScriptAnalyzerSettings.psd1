@{
  ExcludeRules = @(
    # The module deliberately provides familiar interactive aliases such as cd, cdr and mark.
    'PSAvoidUsingCmdletAliases',
    # cde is the documented public configuration variable and exported ancestor variables are a feature.
    'PSAvoidGlobalVars',
    # Navigation commands change session state and must not prompt before changing directory.
    'PSUseShouldProcessForStateChangingFunctions',
    # Recent and frecent commands delegate their WhatIf operations to commands that call ShouldProcess.
    'PSShouldProcess',
    # Pester setup variables are consumed in other scopes, which static analysis cannot follow.
    'PSUseDeclaredVarsMoreThanAssignments',
    # Public pipeline commands retain their current begin/process/end behaviour for compatibility.
    'PSUseProcessBlockForPipelineCommand',
    # Completion callbacks and steppable-pipeline functions have parameters invoked indirectly.
    'PSReviewUnusedParameter',
    # Get-Ancestors is an established public command and changing it would break the API.
    'PSUseSingularNouns',
    # Internal helper functions deliberately use positional calls to keep navigation code concise.
    'PSAvoidUsingPositionalParameters'
  )
}
