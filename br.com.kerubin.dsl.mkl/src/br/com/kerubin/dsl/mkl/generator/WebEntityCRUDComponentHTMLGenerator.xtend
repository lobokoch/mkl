package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FieldObject
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTargetField
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.SmallintType
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*
import br.com.kerubin.dsl.mkl.model.Help

class WebEntityCRUDComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	val closedHTMLTags = #['p-', 'textarea']
	var webComponentType = ''
	
	boolean isOpenTagClosed
	boolean hasFocus = false
	 
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateComponent]
	}
	
	def generateComponent(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.html'
		generateFile(entityFile, entity.doGenerateEntityComponentGenerator)
	}
	
	def CharSequence doGenerateEntityComponentGenerator(Entity entity) {
		val rules = entity.ruleMakeCopies
		
		'''
		<div class="container">
			«entity.generateEntityTitle»
		
		  <form #form1="ngForm" (ngSubmit)="save(form1.form)">
		  	<div class="ui-g">
		  	
				«entity.generateEntityFields»
				«IF !rules.empty»«entity.generateEntityCopies(rules.head)»«ENDIF»
				«entity.generateButtons»
			
			</div>
		  </form>
		  
		  </p-panel>
		  
		</div>
		'''
	}
	
	def CharSequence generateEntityCopies(Entity entity, Rule rule) {
		val makeCopies = rule.apply.makeCopiesExpression
		val title = makeCopies?.title ?: 'Gerar cópias'
		val actionName = rule.getRuleActionMakeCopiesName
		
		val actionButton = rule?.action?.actionButton
		val buttonToolTip = actionButton?.tooltip ?: 'Criar e salvar as cópias.'
		val buttonLabel = actionButton?.label ?: 'Criar cópias'
		val buttonIcon = actionButton?.icon ?: 'pi pi-clone'
		val min = makeCopies.minCopies
		val max = makeCopies.maxCopies
		val hiddeWhen = makeCopies.hiddeWhen
		
		val fielRefDescription = makeCopies?.referenceField?.field?.label ?: makeCopies?.referenceField?.field?.fieldName ?: 'Campo de referência'
		
		val help = makeCopies?.help ?: newHelp('Crie várias cópias do registro atual.')
		val helpFieldNumberOfCopies = makeCopies?.helpFieldNumberOfCopies ?: newHelp('Informe quantas cópias deste registro você deseja criar')
		val helpFieldReferenceField = makeCopies.helpFieldReferenceField ?: newHelp('Campo do tipo data que será usado como referência e terá sua data incrementada automaticamente nos novos registros copiados')
		val helpFieldInterval = makeCopies.helpFieldInterval ?: newHelp('Informe o intervalo de dias que as datas do campo \'' + 
			fielRefDescription + '\' dos registros copiados serão incrementados. Para um intervalo de 30 dias, mantém fixo o dia e incrementa o mês das novas datas')
		
		'''
		 
		<!-- BEGIN make copies -->
		<!-- placeholder="Informe um identificador, exemplo: #luz_2019" -->
		<!-- <div class="invalid-message" *ngIf="copiesMustHaveGroup && !contaPagar.agrupador">Campo obrigatório para gerar cópias.</div> -->
		    <p-accordion *ngIf="isEditing«IF hiddeWhen !== null» && !«makeCopies.hiddeWhenMethodName»()«ENDIF»" class="ui-g-12">
		    	<p-accordionTab>
		    	
		    	<p-header>
		    	<span style="font-weight: bold;">«title»</span>
		    	«help.generateHelp»
		    	</p-header>
		    	
			    <div class="ui-g">
			    	  <div class="ui-g-12">
		    	        <div [innerHTML]="«actionName»Help()"></div>
		    	      </div>
			    
				      <div class="ui-g-12 ui-fluid">
				        <div class="ui-g-12 ui-fluid ui-md-2">
				          <label for="numberOfCopies">
				          Número de cópias
				          «helpFieldNumberOfCopies.generateHelp»
				          </label>
				          <p-spinner size="30" name="numberOfCopies" [(ngModel)]="numberOfCopies" [min]="«min»" [max]="«max»"></p-spinner>
				        </div>
				
				        <div class="ui-g-12 ui-fluid ui-md-2">
				          <label for="copiesReferenceField" style="display: block">
				          Campo de referência
				          «helpFieldReferenceField.generateHelp»
				          </label>
				          <p-dropdown optionLabel="label" name="copiesReferenceField" #copiesReferenceField="ngModel" [options]="copiesReferenceFieldOptions" ngModel [(ngModel)]="copiesReferenceFieldSelected" placeholder="Selecione"></p-dropdown>
				        </div>
				
				        <div class="ui-g-12 ui-md-2 ui-fluid">
				          <label for="copiesReferenceFieldInterval" style="display: block">
				          Intervalo (dias)
				          «helpFieldInterval.generateHelp»
				          </label>
				          <p-spinner size="30" name="copiesReferenceFieldInterval" [(ngModel)]="copiesReferenceFieldInterval" [min]="1" [max]="1000"></p-spinner>
				        </div>
				
				        <div class="ui-g-12 ui-md-2 ui-fluid">
				          <span style="display: block">&nbsp;</span>
				          <button pButton (click)="«actionName»()" type="button" pTooltip="«buttonToolTip»" tooltipPosition="top" icon="«buttonIcon»" label="«buttonLabel»" class="ui-button-info"></button>
				        </div>
				      </div>
				      
			    </div>
		    
		    	</p-accordionTab>
		    </p-accordion>
		    <!-- END make copies -->
		'''
	}
	
	def CharSequence generateButtons(Entity entity) {
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		val hasRulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD.size > 0
		val ruleFormWithDisableCUDMethodName = entity.toRuleFormWithDisableCUDMethodName
		
		val ruleFormCrudButtons = entity.getRuleFormCrudButtons
		
		val crudButtons = ruleFormCrudButtons?.apply?.crudButtons
		val buttonSave = crudButtons.buildCrudButtonSave(entity)
		val buttonNew = crudButtons.buildCrudButtonNew(entity)
		val buttonBack = crudButtons.buildCrudButtonBack(entity)
		
		'''
		
		<div class="ui-g-12 crud-buttons">
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<button«IF hasRulesFormWithDisableCUD» [disabled]="«ruleFormWithDisableCUDMethodName»()"«ENDIF» pButton type="submit" «buttonSave»></button>
			</div>
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<button pButton (click)="begin(form1)" type="button" «buttonNew»></button>
			</div>
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<a routerLink="/«entity.toWebName»" pButton «buttonBack»></a>
			</div>
			«IF !ruleFormActionsWithFunction.empty»
			
			<!-- Begin rule functions -->
			
			«ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join»
			
			<!-- End rule functions -->
			«ENDIF»
		</div>
		
		'''
	}
	
	
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val function = rule.apply.ruleFunction
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		
		val ruleAction = rule.action
		val actionButton = ruleAction.actionButton
		val btnToolTip = actionButton?.tooltip ?: ''
		val btnLabel = actionButton?.label ?: ''
		val btnIcon = actionButton?.icon ?: ''
		val btnClass = actionButton?.cssClass ?: ''
		
		val actionName = ruleAction.toRuleActionName(methodName + '_action')
		
		val ruleActionWhenConditionName = actionName.toRuleActionWhenConditionName
		
		'''
		
		<div class="ui-g-12 ui-md-2 ui-fluid">
			<button pButton [disabled]="!«ruleActionWhenConditionName»()" (click)="«actionName»()" type="button" «IF btnToolTip != ''»pTooltip="«btnToolTip»" tooltipPosition="top"«ENDIF»«IF btnIcon != ''» icon="«btnIcon»"«ENDIF»«IF btnLabel != ''» label="«btnLabel»"«ENDIF»«IF btnClass != ''» class="«btnClass»"«ENDIF»></button>
		</div>
		
		'''
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		var title = entity?.title ?: entity.name		
		val formHelp = entity?.help ?: newHelp('Nesta tela, controle os registros de ' + title.toLowerCase)
		
		val help = newHelp('Mostre ou oculte as dicas de ajuda dos campos.')
		// <div class="kb-no-margins1" style="display: flex; align-items: center; justify-content: center;">
		
		
		'''
		<p-panel>
			<p-header>
				<div class="ui-g kb-no-margins1">
				
				  <div class="ui-g-12 ui-md-10 kb-no-margins1">
				    <div class="kb-form-panel-header">
					  «entity.translationKey.translationKeyFunc»
					    «formHelp.generateHelp»
					</div>
				  </div>
				  
				  <div class="ui-g-12 ui-md-2 kb-no-margins1">
		            <div class="kb-no-margins1" style="display: flex; align-items: center; justify-content: flex-end;">
		              <p-inputSwitch [(ngModel)]="«SHOW_HIDE_HELP»"></p-inputSwitch>
		              <span style="margin-left: 3px;">
		              {{ «SHOW_HIDE_HELP_LABEL_METHOD»() }}
		               «help.generateHelpVisible»
		              </span>
		            </div>
		          </div>
				  
				</div>
			</p-header>
		
		'''
	}
	
	def CharSequence generateEntityFields(Entity entity) {
		hasFocus = false
		'''
		«entity.slots.filter[!mapped].map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		val help = slot.help
		
		val ruleWithSlotAppyHiddeComponent = slot.getRuleWithSlotAppyHiddeComponent
		
		val ruleWithSlotAppyStyleClass = slot.getRuleWithSlotAppyStyleClassForSlot
		var styleClassMethodName = ''
		if (ruleWithSlotAppyStyleClass !== null) {
			styleClassMethodName = slot.toRuleWithSlotAppyStyleClassMethodName
		}
		
		val ruleSearchCEP = entity.ruleSearchCEP
		var Slot cepField = null
		if (ruleSearchCEP !== null) {
			val searchCEP = ruleSearchCEP.apply.searchCEPExpression
			val searchCEPField = searchCEP.cepField.field
			if (searchCEPField.name == slot.name) {
				cepField = searchCEPField
			}
		}
		
		'''
		«IF slot.hasSeparatorBefore»
		«slot.generateSeparator»
		«ENDIF»
		«IF slot.isToMany»
		slot.isToMany
		«ELSE»
		<div class="«slot.webClass»"«IF !styleClassMethodName.empty» [ngClass]="«styleClassMethodName»()"«ENDIF»«IF ruleWithSlotAppyHiddeComponent !== null» «slot.toRuleWithSlotAppyHiddeComponentHTMLDirective»«ENDIF»>
			<label «IF slot.isBoolean»style="display: block" «ENDIF»for="«slot.fieldName»"«IF slot.isHiddenSlot» class="hidden"«ENDIF»>
				«slot.webLabel»
				«IF !slot.isOptional && !slot.isHiddenSlot»<span class="kb-label-required">*</span>«ENDIF»
				«IF help !== null»
				«help.generateHelp»
				«ENDIF»
			</label>
			«IF cepField !== null»
			<div class="ui-inputgroup">
				«slot.generateWebComponent»
				<button pButton type="button" label="Buscar" (click)="searchCEP()"></button>
			</div>
			«ELSE»
			«slot.generateWebComponent»
			«ENDIF»
		</div>
		«IF slot.hasSeparatorAfter»
		«slot.generateSeparator»
		«ENDIF»
		«ENDIF»
		'''
	}
	
	def CharSequence generateHelp(Help help) {
		help.generateHelp('showHideHelp')
	}
	
	def CharSequence generateHelpVisible(Help help) {
		help.generateHelp(null)
	}
	
	def CharSequence generateHelp(Help help, String visibleCondition) {
		val icon = help.icon
		val text = help?.text?.endsWithDot
		val styleClass =  help.styleClass
		
		'''
		<!-- help -->
		<i«IF visibleCondition !== null» *ngIf="«visibleCondition»"«ENDIF» class="«icon»" tooltipStyleClass="«styleClass»" pTooltip="«text»"></i>
		<!-- help -->
		'''
	}
	
	def CharSequence generateSeparator(Slot slot) {
		
		val ruleWithSlotAppyHiddeComponent = slot.getRuleWithSlotAppyHiddeComponent
		
		val separator = slot.separator
		val styleClass = if (separator.styleClass !== null) separator.styleClass else 'separator-default' 
		
		'''
		
		<!-- separator -->
		<div class="ui-g-12"«IF ruleWithSlotAppyHiddeComponent !== null» «slot.toRuleWithSlotAppyHiddeComponentHTMLDirective»«ENDIF»>
			<hr class="«styleClass»">
		</div>
		<!-- separator -->
		
		'''
	}
	
	
	def CharSequence generateWebComponent(Slot slot) {
		webComponentType = '';
		val builder = new StringConcatenationExt()
		builder.concat('<')
		isOpenTagClosed = false
		slot.decoreWebComponent(builder)
		if (! isOpenTagClosed) {
			builder.concat('>')			
		}
		
		// It must close the HTML tag?
		if (closedHTMLTags.exists[webComponentType.startsWith(it)]) {
			builder.concat('</').concat(webComponentType).concat('>')			
		}
		
		// Treats the read only
		if (slot.isUUID || slot.isWebReadOnly) {
			var type = webComponentType.replace('p-', '')
			type = type.toLowerCase			
			
			val openReadOnly = '''
			<div class="«type»-readonly">
			'''
			builder.addIndentAfter(openReadOnly, 0)
			
			
			val closeReadOnly = 
			'''
			</div>
			'''
			builder.add(closeReadOnly)
		}
		
		slot.generateComponentMessages(builder)
		
		val result = builder.build
		result
	}
	
	def CharSequence generateComponentMessages(Slot slot, StringConcatenationExt builder) {
		if (!slot.UUID && !slot.optional) {
			builder.add('''<div class="invalid-message" *ngIf="«slot.fieldName».invalid && «slot.fieldName».dirty">Campo obrigatório.</div>''')
		}
	}
	
	def void decoreWebComponent(Slot slot, StringConcatenationExt builder) {
		slot.decorateWebComponentType(builder)
		slot.decorateWebComponentAppFocus(builder)
		slot.decorateWebComponentNgModel(builder)
		slot.decorateWebComponentName(builder)
		slot.decorateWebComponentOnChange(builder)
		slot.decorateWebComponentRulesWithSlotAppyMathExpression(builder)
		slot.decorateWebComponentApplyRules(builder)
		slot.decorateWebComponentRules(builder)
		
		// Tem que ser por último, porque fecha a tag.
		slot.decorateWebComponentAutoCompleteTemplate(builder)
	}
	
	def void decorateWebComponentApplyRules(Slot slot, StringConcatenationExt builder) {
		// Begin rule AppyDisableComponent at slot
		val rules = slot.getRulesWithSlotAppyDisableComponent
		if (!rules.empty) {
			builder.concat(''' [disabled]="«slot.buildSlotRuleDisableComponentMethodName»()"''')
		}
		// End rule AppyDisableComponent at slot
	}
	
	def void decorateWebComponentRulesWithSlotAppyMathExpression(Slot slot, StringConcatenationExt builder) {
		
		val entity = slot.ownerEntity
		val rulesWithSlotAppyMathExpression = entity.getRulesWithSlotAppyMathExpression
		
		val onBlurList = newArrayList
		if (!rulesWithSlotAppyMathExpression.empty) {
			rulesWithSlotAppyMathExpression.forEach[ rule |
				
				// Looks in the target "with" part
				val targetSlot = (rule.target as RuleTargetField).target.field
				var hasField = targetSlot.name == slot.name
				
				if (!hasField) { // If not found, looks inside the equation
					var expression = rule.apply.fieldMathExpression
					
					val sb = new StringBuilder
					expression.buildRuleApplyFieldMathExpression(sb)
					val expressionStr = sb.toString
					if (expressionStr !== null) {
						val slotName = slot.name
						hasField =  expressionStr.contains('.' + slotName)
					}
				}
				
				if(!hasField && rule.hasWhen) { // and finally, if not found yet, looks in the "when" part.
					var whenExpression = rule.when.expression
					if (whenExpression.left.whenObject instanceof FieldObject) {
						var fieldObject = whenExpression.left.whenObject as FieldObject
						hasField = fieldObject.field.name == slot.name
						while (!hasField && whenExpression.rigth !== null) {
							whenExpression = whenExpression.rigth
							if (whenExpression.left.whenObject instanceof FieldObject) {
								fieldObject = whenExpression.left.whenObject as FieldObject
								hasField = fieldObject.field.name == slot.name
							}
						}
					}
				}
				
				if (hasField) {
					val methodName = targetSlot.toRuleWithSlotAppyMathExpressionMethodName
					if (slot.isTemporal) {
						onBlurList.add('''(onBlur)="«methodName»($event)"''')
						onBlurList.add('''(onClose)="«methodName»($event)"''')
						
					}
					else {
						onBlurList.add('''(blur)="«methodName»($event)"''')
					}
				}
			]
		}
		
		onBlurList.forEach[builder.concat(''' «it.toString» ''').concat('\r\n')]
		
	}
	
	def void decorateWebComponentAppFocus(Slot slot, StringConcatenationExt builder) {
		if (!hasFocus && !slot.isHiddenSlot && slot !== slot.ownerEntity.id) {
			if (!slot.isEntity) { // Autocomplete não pode receber focu assim, tem que ver outro jeito.
				builder.concat(''' appFocus''')
			}
			hasFocus = true;
		}
	}
	
	def void decorateWebComponentName(Slot slot, StringConcatenationExt builder) {
		builder.concat(''' name="«slot.fieldName»"''')
	}
	
	def void decorateWebComponentOnChange(Slot slot, StringConcatenationExt builder) {
		if (slot.onChange) {
			builder.concat(''' (onChange)="«slot.fieldName»Change($event)"''')
		}
	}
	
	def void decorateWebComponentRules(Slot slot, StringConcatenationExt builder) {
		if (!slot.UUID && !slot.optional) {
			builder.concat(' required')
		}
	}
	
	
	def void decorateWebComponentNgModel(Slot slot, StringConcatenationExt builder) {
			builder.concat(''' #«slot.fieldName»="ngModel" ngModel [(ngModel)]="«slot.ownerEntity.fieldName».«slot.fieldName»"''')
	}
	
	def void decorateWebComponentAutoCompleteTemplate(Slot slot, StringConcatenationExt builder) {
		if (slot.isEntity) {
			val entity = slot.asEntity
			var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id]
			if (resultSlots.isEmpty) {
				resultSlots = entity.slots.filter[it.autoCompleteResult]
			}
			if (!resultSlots.isEmpty) {
				builder.concat('>')
				isOpenTagClosed = true
				builder.addIndent('''
					<ng-template let-«slot.fieldName» pTemplate="item">
						<div class="ui-helper-clearfix">{{ «slot.webAutoCompleteFieldConverter»(«slot.fieldName») }}</div>
					</ng-template>
				''')
			}
			
		}
	}
	
	def void decorateWebComponentType(Slot slot, StringConcatenationExt builder) {
		
		if (slot.isEntity) {
			// Pega como resultado o primeiro campo de resultado que não seja o id da entidade, caso não tenha nenhum, ai traz o id da entidade como campo de resultado.
			webComponentType = 'p-autoComplete'
			builder
			.concat('''«webComponentType» ''')
			.concat('''«IF slot.isWebReadOnly»[readonly]="true"«ENDIF»''').concat('\r\n')
			.concat('''«webComponentType» placeholder="Digite para pesquisar..." [dropdown]="true" [forceSelection]="true"''').concat('\r\n')
			.concat(''' [suggestions]="«slot.webAutoCompleteSuggestions»"''').concat('\r\n')
			.concat(''' (completeMethod)="«slot.toAutoCompleteName»($event)"''').concat('\r\n')
			.concat(''' (onClear)="«slot.toAutoCompleteClearMethodName»($event)"''').concat('\r\n')
			.concat(''' (onBlur)="«slot.toAutoCompleteOnBlurMethodName»($event)"''').concat('\r\n')
			builder.concat(''' [field]="«slot.webAutoCompleteFieldConverter»"''').concat('\r\n')
			return
		}
		else if (slot.isEnum){
			webComponentType = 'p-dropdown'
			builder.concat('''«webComponentType»«IF slot.isWebReadOnly» [readonly]="true"«ENDIF» [options]="«slot.webDropdownOptions»" placeholder="Selecione um item..."''')
			return
		}
		
		// Is a basic type
		val basicType = slot.basicType
		
		var inputType = if (slot.hiddenSlot) 'hidden' else 'text'
		
		if (basicType instanceof StringType) {
			val stringType = basicType as StringType
			if (slot.isPassword) {
				inputType = 'password'
				webComponentType = 'input'
				builder.concat('''«webComponentType» type="«inputType»" pInputText ''')			
			}
			// Must be a TextArea?
			else if (stringType.length > 255) {
				webComponentType = 'textarea'
				builder.concat('''«webComponentType» pInputTextarea rows="3"''')			
			}
			else { // Input Text
				webComponentType = 'input'
				builder.concat('''«webComponentType» type="«inputType»" pInputText''')				
			}
		}
		else if (basicType instanceof SmallintType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof IntegerType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof DoubleType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof MoneyType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» pInputText type="«inputType»" currencyMask [options]="{prefix: '', thousands: '.', decimal: ',', allowNegative: false}" placeholder="0,00"''')
		}
		else if (basicType instanceof BooleanType) {
			webComponentType = 'p-inputSwitch'
			builder.concat(webComponentType)
		}
		else if (basicType instanceof DateType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» [locale]="«getCalendarLocaleSettingsVarName»" dateFormat="dd/mm/yy"«IF slot.isWebReadOnly» [disabledDays]="[0,1,2,3,4,5,6]" [readonlyInput]="true"«ENDIF»''')
		}
		else if (basicType instanceof TimeType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» [locale]="«getCalendarLocaleSettingsVarName»" dateFormat="hh:MM:ss"«IF slot.isWebReadOnly» [disabledDays]="[0,1,2,3,4,5,6]" [readonlyInput]="true"«ENDIF»''')
		}
		else if (basicType instanceof DateTimeType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» [locale]="«getCalendarLocaleSettingsVarName»" dateFormat="dd/mm/yy" [showTime]="true"«IF slot.isWebReadOnly» [disabledDays]="[0,1,2,3,4,5,6]" [readonlyInput]="true"«ENDIF»''')
		}
		else if (basicType instanceof UUIDType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof ByteType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		
		if (slot.isUUID || (slot.isWebReadOnly && webComponentType == 'input')) {
			builder.concat(''' readonly''')
		}
		
	}
	
	def CharSequence generateInputComponent(Slot slot) {
		val builder = new StringConcatenationExt()
		
		val result = builder.build
		result
	}
	
	
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO»[] {
		«ELSE»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO» {
		«ENDIF»
			return this.«slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO»[]) {
		«ELSE»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO») {
		«ENDIF»
			this.«slot.name.toFirstLower» = value;
		}
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.imports.clear
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
	
}