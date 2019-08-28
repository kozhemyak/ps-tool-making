## ----------------------------------------------------------------------------
## Structures

enum VSTSBuildResult {
    Succeeded               
    SucceededWithIssues     
    Failed                  
    Cancelled               
    Skipped                 
}

enum VSTSLogType {
    Warning     # Highlight the line in the log red and add to the summary pane
    Error       # Highlight the line in the log orange and add to the summary pane
}

enum VSTSHighlightType {
    Error       # Highlight the line in the log red
    Warning     # Highlight the line in the log orange
    Section     # Highlight the line in the log green
    Command     # Highlight the line in the log blue
    Debug       # Highlight the line in the log gray (or purple)
}

## ----------------------------------------------------------------------------
## Function

<#
.SYNOPSIS
Отправка сообщений в TFS/VSTS с использованием подсветки.

.DESCRIPTION
Можно использовать как для отправки уведомлений в чат, так и для задания
статуса сборке и прерыванию выполнения скрпта одной командой.

.PARAMETER InputObject
Текст сообщений или объекты для вывода на экран. Может быть пустым.

.PARAMETER Type
Тип подсветки сообщений в VSTS логе. 
Возможные варианты: Error, Warning, Section, Command, Debug.
По умолчанию не задан и не влияет на вывод.

.PARAMETER Result
Задаёт статус сборки и шага. 
Возможные варианты: Succeeded, SucceededWithIssues, Failed, Cancelled, Skipped.

.PARAMETER Summary
Работает только для типа ERROR и WARNING. 
Повышая их до ошибки, информация о сообщении выводится на титульной странице сборки.

.PARAMETER Exit
Выполняет команду EXIT в конце для выполнения прерывания сборки.
Если не задан Result, то используется код 1, для всех остальных используется 0.

.EXAMPLE
    # Обычние сообщение без изменений
    PS> Write-VSTSMessage "<Message>"

.EXAMPLE
    # Задать тип подсветки в логе
    PS> Write-VSTSMessage "<Message>" -Type Warning

.EXAMPLE
    # Задать статус сборки / задания
    PS> Write-VSTSMessage "<Message>" -Type Error -Result Failed

.EXAMPLE
    # Задать статус сборки / задания c выходом из скрипта или шага выполнения
    PS> Write-VSTSMessage "<Message>" -Type Error -Result Cancelled -Exit

.EXAMPLE
    # Добавить сообщение на центральную панель выкладки, только для ERROR и WARNING типа
    PS> Write-VSTSMessage "<Message>" -Type Error -Summary
#>
function Write-VSTSMessage {
    [CmdletBinding()]
    param (
        # Messages
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [psobject[]] $InputObject,

        # Set the type of the messages, if it is empty the output is not colored
        [VSTSHighlightType] $Type,

        # Set the result of the entire task
        [Alias("TaskResult")]
        [VSTSBuildResult] $Result,

        # Add to summary (only if ERROR or WARNING)
        [Alias("Global")]
        [switch] $Summary,

        # Stop processing the sript or task
        [Alias("Finish")]
        [switch] $Exit
    )
    
    begin {
        Write-Verbose "Setting the header for message"
        if (-not [string]::IsNullOrEmpty($Type)) {
            $MessageType = "##[${Type}]"
        } else {
            $MessageType = ""
        }
    }
    
    process {
        foreach ($Object in $InputObject) {
            Write-Verbose "Proceccing the '${Object}'"
            if ($Summary.IsPresent) {
                Write-Verbose "The key -SUMMARY is set. The message will added to summary pane."
                switch ($Type) {
                    Error      { Write-Output ("##vso[task.logissue type=error;]{0}" -f $Object.ToString()) }
                    Warning    { Write-Output ("##vso[task.logissue type=warning;]{0}" -f $Object.ToString()) }
                    default    {
                        Write-Verbose "Only messages with type ERROR/WARNING are included to the summary pane."
                        Write-Output ("{0}{1}" -f $MessageType, $Object.ToString()) 
                    }
                }
            } else {
                Write-Output ("{0}{1}" -f $MessageType, $Object.ToString())
            }
        }
    }
    
    end {
        if (-not [string]::IsNullOrEmpty($Result)) {
            Write-Verbose "Setting the build status to '${Result}'"
            Write-Verbose "The task status is '${Result}'"
            Write-Output  "##vso[task.complete result=${Result};]DONE"
        }
        
        if ($Exit.IsPresent) {
            Write-Verbose "The switch '-Exit' is set. Break the execution."
            if ([string]::IsNullOrEmpty($Result)) {
                Write-Verbose "The TaskResult is not set. Produce the error during the execution."
                Exit 1
            } else {
                Exit 0
            }
        }
    }
}