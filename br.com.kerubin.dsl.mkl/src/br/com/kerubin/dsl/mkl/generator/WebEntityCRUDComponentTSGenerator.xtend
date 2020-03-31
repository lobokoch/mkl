package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.generator.web.searchcep.WebSearchCEPServiceGenerator
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTargetField
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt
import java.util.Arrays
import java.util.LinkedHashSet
import java.util.Set

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*

class WebEntityCRUDComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	val LinkedHashSet<String> importsSet = newLinkedHashSet
	
	val LinkedHashSet<String> customActions = newLinkedHashSet
	
	
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
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityTSComponent)
		
		if (entity.enableWebCustomService) {
			val fileName = path + entity.toEntityWebCustomServiceFileName + '.ts'
			generateFile(fileName, entity.doGenerateEntityTSCustomService)
		}
	}
	
	def CharSequence doGenerateEntityTSCustomService(Entity entity) {
		val component = entity.toEntityWebCRUDComponentName
		val customServiceName = entity.toEntityWebCustomServiceClassName
		val componentClassName = entity.toEntityWebComponentClassName
		
		'''
		import { «entity.toEntityWebComponentClassName» } from './«component»';
		import { Injectable } from '@angular/core';
		
		@Injectable()
		export class «customServiceName» {
		
		  component: «componentClassName»;
		
		  setComponent(component: «componentClassName») {
		    this.component = component;
		  }
		
		  «customActions.map[it.generateActionDefinition].join»
		
		}
		
		'''	
	}
	
	def CharSequence generateActionDefinition(String methodDef) {
		
		var String returnValue = null
		if (methodDef.endsWith(': boolean')) {
			returnValue = 'return true'
		} else if (methodDef.endsWith(': string')) {
			returnValue = 'return \'\''
		} 
		
		'''
		
		«methodDef» {
			// This method can be overridden.
			«IF returnValue !== null»
			«returnValue»;
			«ENDIF»
		}
		
		'''
	}
	
	def CharSequence doGenerateEntityTSComponent(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		val customServiceName = entity.toEntityWebCustomServiceClassName
		val customServiceVar = customServiceName.toFirstLower
		
		val ruleMakeCopies = entity.ruleMakeCopies
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val rulesFormOnUpdate = entity.rulesFormOnUpdate
		val rulesFormOnInit = entity.rulesFormOnInit
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		val rulesWithSlotAppyStyleClass = entity.rulesWithSlotAppyStyleClass
		val rulesWithSlotAppyHiddeComponent = entity.rulesWithSlotAppyHiddeComponent
		val rulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD
		val rulesFormBeforeSave = entity.getRulesFormBeforeSave
		
		val rulesWithSlotAppyMathExpression = entity.getRulesWithSlotAppyMathExpression
		
		val hasCalendar = entity.hasDate
		
		val rememberedSlots = entity.slots.filter[it.isWebRememberValue]
		
		val rulesPolling = entity.ruleFormPolling
		val ruleSearchCEP = entity.ruleSearchCEP
		
		val rulesDisableComponent = entity.getRulesWithSlotAppyDisableComponent
		
		val slotForFocus = entity.defaultSlotForFocus
		
		if (slotForFocus !== null) {
			if (slotForFocus.isEntity) {
				imports.add('''import { AutoComplete } from 'primeng/autocomplete';''')
				imports.add('''import { ViewChild } from '@angular/core';''')
			}
			else {
				imports.add('''import { ElementRef, ViewChild } from '@angular/core';''')
			}
		}
		
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		
		imports.add('''import { «serviceName» } from './«webName».service';''')
		
		if (entity.enableWebCustomService) {
			imports.add('''import { «customServiceName» } from './custom-«webName».service';''')
		}
		
		imports.add('''import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';''')
		if (entity.hasDate || entity.fieldsAsEntityHasDate) {
			imports.add('''import * as moment from 'moment';''')
		}
		entity.slots.filter[it.isEntity].forEach[ 
			val slotAsEntity = it.asEntity
			imports.newLine
			
			if (slotAsEntity.isNotSameName(entity)) { // Is not a field of same type of mine entity
				imports.add('''import { «slotAsEntity.toEntityWebServiceClassName» } from './«slotAsEntity.toEntityWebServiceNameWithPath»';''')
				imports.add('''import { «slotAsEntity.toDtoName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
			}
			imports.add('''import { «slotAsEntity.toAutoCompleteName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
		]
		entity.slots.filter[it.isEnum].forEach[
			val slotAsEnum = it.asEnum
			imports.newLine
			imports.add('''import { «slotAsEnum.toDtoName» } from '«service.serviceWebEnumsPathName»';''')
		]
		
		if (!ruleMakeCopies.empty) {
			imports.add('''import {SelectItem, ConfirmationService} from 'primeng/api';''')
		}
		
		if (ruleSearchCEP !== null) {
			imports.add('''import { «WebSearchCEPServiceGenerator.SERVICE_CLASS_NAME» } from './../../../../searchcep/«WebSearchCEPServiceGenerator.SERVICE_NAME»';''')
		}

		imports.add('''import { MessageHandlerService } from 'src/app/core/message-handler.service';''')
		
		/*if (entity.hasPassword) {
			imports.add('''import {PasswordModule} from 'primeng/password';''')
		}*/
		
		val component = entity.toEntityWebCRUDComponentName
		val body = '''
		
		@Component({
		  selector: '«entity.toEntityWebCRUDAppComponentName»',
		  templateUrl: './«component».html',
		  styleUrls: ['./«component».css']
		})
		
		export class «entity.toEntityWebComponentClassName» implements OnInit {
			«SHOW_HIDE_HELP» = false; // for show/hide help.
			
			«IF hasCalendar»
			
			«getCalendarLocaleSettingsVarName»: any;
			
			«ENDIF»
			«IF !ruleMakeCopies.empty»«initializeMakeCopiesVars(ruleMakeCopies.head)»«ENDIF»
			«fieldName» = new «dtoName»();
			«IF !rememberedSlots.empty»
			
			// Remember fields values
			«entity.buildRememberValueEntityField» = new «dtoName»();
			
			«ENDIF»
			«entity.slots.filter[isEntity].map[mountAutoCompleteSuggestionsVar].join('\n\r')»
			«entity.slots.filter[isEnum].map[mountDropdownOptionsVar].join('\n\r')»
			«IF entity.isEnableReplication»«entity.entityReplicationQuantity» = 1;«ENDIF»
			«IF !rulesPolling.empty»
			«rulesPolling.generatePollingVars»
			«ENDIF»
			«IF slotForFocus !== null»
			
			@ViewChild('«slotForFocus.webElementRefName»', {static: true}) defaultElementRef: «IF slotForFocus.isEntity»AutoComplete«ELSE»ElementRef«ENDIF»;
			«ENDIF»
			
			constructor(
			    private «serviceVar»: «serviceName»,
			    «IF entity.enableWebCustomService»
			    private «customServiceVar»: «customServiceName»,
			    «ENDIF»
			    private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»,
			    «entity.slots.filter[isEntity && it.asEntity.isNotSameName(entity)].map[mountServiceConstructorInject].join('\n\r')»
			    private route: ActivatedRoute,
			    «IF !ruleMakeCopies.empty»
			    private confirmation: ConfirmationService,
			    «ENDIF»
			    «IF ruleSearchCEP !== null»
			    private «WebSearchCEPServiceGenerator.SERVICE_CLASS_NAME.toFirstLower»: «WebSearchCEPServiceGenerator.SERVICE_CLASS_NAME»,
			    «ENDIF»
			    private messageHandler: MessageHandlerService
			) { 
				«IF entity.enableWebCustomService»
				this.«customServiceVar».setComponent(this);
				«ENDIF»
				«customServiceVar.buildCustomActionBefore('constructor', entity)»
				«entity.slots.filter[isEnum].map['''this.«it.webDropdownOptionsInitializationMethod»();'''].join('\n\r')»
				«IF !ruleMakeCopies.empty»
				this.initializeCopiesReferenceFieldOptions();
				«ENDIF»
				«customServiceVar.buildCustomActionAfter('constructor', entity)»
			}
			
			ngOnInit() {
				«customServiceVar.buildCustomActionBefore('onInit', entity)»
				«IF hasCalendar»
				this.initLocaleSettings();
				«ENDIF»
				«IF !rulesFormOnInit.empty»
				this.rulesOnInit();
				
				«ENDIF»
				«IF !rulesFormOnCreate.empty»
				this.rulesOnCreate();
				
				«ENDIF»
				«IF entity.hasEnumSlotsWithDefault»
				this.initializeEnumFieldsWithDefault();
				«ENDIF»
			    const id = this.route.snapshot.params['id'];
			    if (id) {
			      this.get«dtoName»ById(id);
			    }
			    «customServiceVar.buildCustomActionAfter('onInit', entity)»
			    «IF slotForFocus !== null»
			    «IF !slotForFocus.isEntity»
			    «callDefaultElementSetFocus»
			    «ELSE»
			    setTimeout(function() {
			    	«callDefaultElementSetFocus»
			    }.bind(this), 1);
			    «ENDIF»
			    «ENDIF»
			}
			
			«generateGetShowHideHelpLabel»
			
			begin(form: FormControl) {
			    form.reset();
			    setTimeout(function() {
			    	«customServiceVar.buildCustomActionBefore('onNewRecord', entity)»
			      this.«fieldName» = new «dtoName»();
			      «IF !rulesFormOnInit.empty»
			      this.rulesOnInit();
	  			  «ENDIF»
			      «IF entity.hasEnumSlotsWithDefault»
			      this.initializeEnumFieldsWithDefault();
			      «ENDIF»
				  «IF !rememberedSlots.empty»
				  	
				  	this.«entity.buildApplyRememberValuesMethodName»();
				  	
				  «ENDIF»
				  «customServiceVar.buildCustomActionAfter('onNewRecord', entity)»
				  «IF slotForFocus !== null»
				  «callDefaultElementSetFocus»
				  «ENDIF»
			    }.bind(this), 1);
			}
			
			validateAllFormFields(form: FormGroup) {
			    Object.keys(form.controls).forEach(field => {
			      const control = form.get(field);
			
			      if (control instanceof FormControl) {
			        control.markAsDirty({ onlySelf: true });
			      } else if (control instanceof FormGroup) {
			        this.validateAllFormFields(control);
			      }
			    });
			}
			
			save(form: FormGroup) {
				if (!form.valid) {
			      this.validateAllFormFields(form);
			      return;
			    }
				«IF !rulesFormBeforeSave.empty»
				
				if (!this.«DO_RULES_FORM_BEFORE_SAVE_METHOD»()) {
					return;
				}
				
				«ENDIF»
				«IF !rememberedSlots.empty»
				
				this.«entity.buildRememberValuesMethodName»();
				
				«ENDIF»
				«customServiceVar.buildCustomActionBefore('save', entity)»
			    if (this.isEditing) {
			      this.update();
			    } else {
			      this.create();
			    }
				«IF !ruleMakeCopies.empty»
				this.initializeCopiesReferenceFieldOptions();
				«ENDIF»
				«customServiceVar.buildCustomActionAfter('save', entity)»
			}
			«IF !rulesFormBeforeSave.empty»
			«rulesFormBeforeSave.generateRulesFormBeforeSave»
			«ENDIF»
			create() {
				«customServiceVar.buildCustomActionBefore('create', entity)»
				«IF !rulesFormOnCreate.empty»
				this.rulesOnCreate();
				«ENDIF»
				
			    this.«serviceVar».create(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.messageHandler.showSuccess('Registro criado com sucesso!');
			      «customServiceVar.buildCustomActionAfter('create', entity)»
			      «IF slotForFocus !== null»
			      «callDefaultElementSetFocus»
			      «ENDIF»
			    }).
			    catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			update() {
				«customServiceVar.buildCustomActionBefore('update', entity)»
				«IF !rulesFormOnUpdate.empty»
				this.rulesOnUpdate();
				
				«ENDIF»
			    this.«serviceVar».update(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.messageHandler.showSuccess('Registro alterado!');
			      «customServiceVar.buildCustomActionAfter('update', entity)»
			      «IF slotForFocus !== null»
			      «callDefaultElementSetFocus»
			      «ENDIF»
			    })
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			get«dtoName»ById(id: string) {
				«buildCustomActionBefore(new ActionConfig()
					.setEntity(entity)
					.setCustomServiceName(customServiceVar)
					.setAction('getById')
					.setParams(Arrays.asList('id'))
					.setParamsTypes(Arrays.asList('string'))
				)»
			    this.«serviceVar».retrieve(id)
			    .then((«fieldName») => { 
			    	this.«fieldName» = «fieldName»;
			    	«buildCustomActionAfter(new ActionConfig()
					.setEntity(entity)
					.setCustomServiceName(customServiceVar)
					.setAction('getById')
					.setParams(Arrays.asList('id'))
					.setParamsTypes(Arrays.asList('string'))
				)»
			    })
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			}
			
			get isEditing() {
			    return Boolean(this.«fieldName».id);
			}
			
			«IF entity.hasEnumSlotsWithDefault»
			«entity.initializeEnumSlotsWithDefault»
			«ENDIF»
			
			«IF entity.isEnableReplication»
			
			replicar«dtoName»() {
			    this.«serviceVar».replicar«dtoName»(this.«fieldName».id, this.«fieldName».agrupador, this.«entity.entityReplicationQuantity»)
			    .then((result) => {
			      if (result === true) {
			        this.messageHandler.showSuccess('Os registros foram criados com sucesso.');
			      } else {
			        this.messageHandler.showError('Não foi possível criar os registros.');
			      }
			    })
			    .catch(error => {
			      this.messageHandler.showError(error);
			    });
			  }
			«ENDIF»
			
			«entity.slots.filter[isEntity].map[mountAutoComplete].join('\n\r')»
			
			«entity.slots.filter[isEnum].map[it.generateEnumInitializationOptions].join»
			
			«buildTranslationMethod(service)»
			
			«ruleMakeCopies.map[generateRuleMakeCopiesActions].join»
			«ruleMakeCopies.map[generateInitializeCopiesReferenceFieldOptions].join»
			«ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join»
			«IF !rulesFormOnInit.empty»
			rulesOnInit() {
				«rulesFormOnInit.map[it.generateRuleFormOnInit(entity.fieldName, importsSet)].join»
			}
			
			«ENDIF»
			«IF !rulesFormOnCreate.empty»
			rulesOnCreate() {
				«rulesFormOnCreate.map[it.generateRuleFormOnCreate(entity.fieldName, importsSet)].join»
			}
			
			«ENDIF»
			«IF !rulesFormOnUpdate.empty»
			rulesOnUpdate() {
				«rulesFormOnUpdate.map[it.generateRuleFormOnUpdate(entity.fieldName, importsSet)].join»
			}
			
			«ENDIF»
			
			«IF !rulesWithSlotAppyStyleClass.empty»
												
			// Begin RuleWithSlotAppyStyleClass 
			«rulesWithSlotAppyStyleClass.map[it.generateRuleWithSlotAppyStyleClass].join»
			// End Begin RuleWithSlotAppyStyleClass
			«ENDIF»
			
			«IF !rulesWithSlotAppyHiddeComponent.empty»
												
			// Begin RuleWithSlotAppyHiddeComponent 
			«rulesWithSlotAppyHiddeComponent.map[it.generateRuleWithSlotAppyHiddeComponent].join»
			// End Begin RuleWithSlotAppyHiddeComponent
			«ENDIF»
			
			«IF !rulesDisableComponent.empty»
												
			// Begin RuleDisableComponent 
			«rulesDisableComponent.map[it.generateRuleDisableComponent].join»
			// End Begin RuleDisableComponent
			«ENDIF»
			
			«IF !rulesWithSlotAppyMathExpression.empty»
												
			// Begin RulesWithSlotAppyMathExpression 
			«rulesWithSlotAppyMathExpression.map[it.generateRuleWithSlotAppyMathExpression].join»
			// End Begin RulesWithSlotAppyMathExpression
			«ENDIF»
			
			«IF !rulesFormWithDisableCUD.empty»
			«rulesFormWithDisableCUD.head.generateRuleFormWithDisableCUD»
			«ENDIF»
			«IF hasCalendar»
			«generateInitLocaleSettings»
			«ENDIF»
			
			«IF !rememberedSlots.empty»
			«entity.buildApplyRememberValuesMethodName»() {
				if (this.«entity.fieldName») {
					«rememberedSlots.map[it.buildAssignRememberValue].join»
				}
			}
			
			«entity.buildRememberValuesMethodName»() {
				if (this.«entity.fieldName») {
					«rememberedSlots.map[it.buildApplyRememberValue].join»
				}
			}
			«ENDIF»
			«IF !rulesPolling.empty»
			«rulesPolling.generatePollingMethodsForm»
			«ENDIF»
			«IF ruleSearchCEP !== null»
			«ruleSearchCEP.generateSearchCEP»
			«ENDIF»
			
			«entity.slots.filter[it.onChange].map[mountSlotOnChange].join('\n\r')»
			«IF slotForFocus !== null»
						
			«getDefaultElementSetFocusMethodName»() {
				try {
			    	this.defaultElementRef.«IF slotForFocus.isEntity»focusInput()«ELSE»nativeElement.focus()«ENDIF»;
			    } catch (error) {
			    	console.log('Error setting focus at «getDefaultElementSetFocusMethodName»:' + error);
			    }
			}
			«ENDIF»
		}
		'''
		
		val source = imports.ln.toString /*+ importsSet.join('\r\n')*/ + '\r\n' + body
		source
	}
	
	def CharSequence generateRulesFormBeforeSave(Iterable<Rule> rules) {
		
		'''
		
		// Begin rulesFormBeforeSave
		«DO_RULES_FORM_BEFORE_SAVE_METHOD»(): boolean {
			«rules.map[it.buildApplyRuleFormBeforeSave].join»
			return true;
		}
		// End rulesFormBeforeSave
		
		'''
		
	}
	
	def CharSequence buildApplyRuleFormBeforeSave(Rule rule) {
		val hasWhen = rule.hasWhen
		var String whenExpression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			whenExpression = resultStrExp.toString
		}
		
		val errorMessage = rule?.apply?.ruleError.buildRuleErrorMessageForTypeScript		
		
		'''
		
		if («whenExpression») {
			this.messageHandler.showError(«errorMessage»);
			return false;
		}
		
		'''
		
	}
	
	def CharSequence generateGetShowHideHelpLabel() {		
		'''
		«SHOW_HIDE_HELP_LABEL_METHOD»(): string {
			return this.«SHOW_HIDE_HELP» ? 'Ocultar ajuda' : 'Mostrar ajuda';
		}
		'''
	}
	
	def CharSequence mountSlotOnChange(Slot slot) {
		val config = new ActionConfig()
			.setEntity(slot.ownerEntity)
			.setCustomServiceName(slot.ownerEntity.toEntityWebCustomServiceVarName)
			.setAction(slot.fieldName.concat('Change'))
			.setParams(Arrays.asList('event'))
			.setParamsTypes(Arrays.asList('any'))
			.setIsVoid(true)
			
		
		'''
		«slot.fieldName»Change(event: any) {
			«IF config.entity.enableWebCustomService»
			«buildCustomActionBefore(config)»
			«ELSE»
			// Do nothing yet.
			«ENDIF»
		}
		'''
	}
	
	def CharSequence buildCustomActionBefore(String customServiceName, String action, Entity entity) {
		val config = new ActionConfig()
		.setEntity(entity)
		.setCustomServiceName(customServiceName)
		.setAction(action)
		
		buildCustomActionBefore(config)
	}
	
	def CharSequence buildCustomActionAfter(String customServiceName, String action, Entity entity) {
		val config = new ActionConfig()
		.setEntity(entity)
		.setCustomServiceName(customServiceName)
		.setAction(action)
		
		buildCustomActionAfter(config)
	}
	
	def CharSequence buildCustomActionBefore(ActionConfig config) {
		config.prefix = 'before';
		buildCustomAction(config)
	}
	
	def CharSequence buildCustomActionAfter(ActionConfig config) {
		config.prefix = 'after';
		buildCustomAction(config)
	}
		
	def CharSequence buildCustomAction(ActionConfig config) {
		if (config.entity === null) {
			throw new IllegalArgumentException('ActionConfig.entity cannot be null.')
		}
		
		if (/*config.entity === null || */!config.entity.enableWebCustomService)  {
			return ''
		}
		
		val sbMethoCall = new StringBuilder
		val sbMethoDefine = new StringBuilder
		if (config.prefix !== null) {
			sbMethoDefine.append(config.prefix)
			sbMethoDefine.append(config.action.toFirstUpper)
		}
		else {
			sbMethoDefine.append(config.action.toFirstUpper)
		}
		
		sbMethoDefine.append('(');
		sbMethoCall.append(sbMethoDefine.toString)
		
		if (config.params !== null) {
			for (var i = 0; i < config.params.size; i++) {
				if (i > 0) {
					sbMethoDefine.append(', ')
					sbMethoCall.append(', ')
				}
				sbMethoDefine.append(config.params.get(i)).append(': ').append(config.paramsTypes.get(i))
				sbMethoCall.append(config.params.get(i))
			}
		}
		
		sbMethoDefine.append(')');
		sbMethoCall.append(')');
		
		if (!config.isVoid) {
			sbMethoDefine.append(': boolean');
		}
		
		customActions.add(sbMethoDefine.toString);
		
		'''
		
		// Begin custom action.
		«IF config.isVoid»
		this.«config.customServiceName».«sbMethoCall.toString»;
		«ELSE»
		if (!this.«config.customServiceName».«sbMethoCall.toString») {
			return;
		}
		«ENDIF»
		// End custom action.
		
		'''
	}
	
	
	def CharSequence buildAssignRememberValue(Slot slot) {
		'''
		«slot.buildAssignFieldForRememberValue»
		'''
	}
	
	def CharSequence buildApplyRememberValue(Slot slot) {
		'''
		«slot.buildApplyFieldFromRememberValue»
		'''
	}
	
	def CharSequence generateInitLocaleSettings() {
		'''
		
		initLocaleSettings() {
			this.«getCalendarLocaleSettingsVarName» = this.«service.toTranslationServiceVarName».«getCalendarLocaleSettingsMethodName»();
		}
		
		'''
	}
	
	def CharSequence generateRuleFormWithDisableCUD(Rule rule) {
		val entity = rule.ruleOwnerEntity
		val methodName = entity.toRuleFormWithDisableCUDMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		
		'''
		
		«methodName»() {
			const expression = «expression»;
			return expression;
		}
		'''
	}
	
	def CharSequence generateRuleWithSlotAppyMathExpression(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val methodName = slot.toRuleWithSlotAppyMathExpressionMethodName
		
		val hasWhen = rule.hasWhen
		var String whenExpression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			whenExpression = resultStrExp.toString
		}
		
		var applyExpression = 'null'
		if (rule.apply !== null && rule.apply.hasFieldMathExpression) {
			val resultStrExp = new StringBuilder
			rule.apply.fieldMathExpression.buildRuleApplyFieldMathExpression(resultStrExp)
			applyExpression = resultStrExp.toString
		}
		
		val entity = slot.ownerEntity
		val thisEntity = 'this.' + entity.fieldName
		
		'''
		
		«methodName»(event) {
			if («thisEntity») {
				const whenExpression = «whenExpression»;
				if (whenExpression) {
					«thisEntity».«slot.fieldName» = «applyExpression»;
				}
			}
		}
		'''
	}
	
	def CharSequence generateRuleDisableComponent(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val methodName = slot.buildSlotRuleDisableComponentMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		'''
		
		«methodName»() {
			const expression = «expression»;
			return expression;
		}
		'''
	}
	
	def CharSequence generateRuleWithSlotAppyHiddeComponent(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val methodName = slot.toRuleWithSlotAppyHiddeComponentMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		'''
		
		«methodName»() {
			const expression = «expression»;
			if (expression) {
				return 'none'; // Will hidde de component.
			} else {
				return 'inline'; // Default css show element value.
			}
		}
		'''
	}
	
	def CharSequence generateRuleWithSlotAppyStyleClass(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val methodName = slot.toRuleWithSlotAppyStyleClassMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		val styleClass = rule.apply.getResutValue
		
		'''
		
		«methodName»() {
			const expression = «expression»;
			if (expression) {
				return '«styleClass»';
			} else {
				return '';
			}
		}
		'''
	}
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val function = rule.apply.ruleFunction
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		val ruleAction = rule.action
		val actionName = ruleAction.toRuleActionName(methodName + '_action')
		val ruleActionWhenConditionName = actionName.toRuleActionWhenConditionName
		
		val hasWhen = rule.hasWhen
		var String expression = null
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenForGridRowStyleClass(resultStrExp)
			expression = resultStrExp.toString
		}
		
		'''
		
		«ruleActionWhenConditionName»(): boolean {
			«IF hasWhen»		    
			return «expression»;
			«ELSE»
			return true;
			«ENDIF»
		}
		  
		«actionName»() {
			this.«methodName»();
		}
		
		«methodName»() {
		    this.«serviceVar».«methodName»(this.«fieldName»)
		    .then((«fieldName») => {
		      if («fieldName») { // Can be null
		      	this.«fieldName» = «fieldName»;
		      }
		      this.messageHandler.showSuccess('Operação executada com sucesso.');
		    })
		    .catch(error => {
		      this.messageHandler.showError(error);
		    });
		}
		'''
	}
	
	def CharSequence generateRuleFormOnInit(Rule rule, String targetObject, Set<String> imports) {
		'''
		«rule.apply.buildRuleApplyForWeb(targetObject, imports)»
		'''
	}
	
	def CharSequence generateRuleFormOnCreate(Rule rule, String targetObject, Set<String> imports) {
		'''
		«rule.apply.buildRuleApplyForWeb(targetObject, imports)»
		'''
	}
	
	def CharSequence generateRuleFormOnUpdate(Rule rule, String targetObject, Set<String> imports) {
		'''
		«rule.apply.buildRuleApplyForWeb(targetObject, imports)»
		'''
	}
	
	
	
	def CharSequence generateInitializeCopiesReferenceFieldOptions(Rule rule) {
		'''
		 
		initializeCopiesReferenceFieldOptions() {
		    this.copiesReferenceFieldOptions = [
		      this.copiesReferenceField
		    ];
		
		    this.copiesReferenceFieldSelected = this.copiesReferenceField;
		    
		    this.numberOfCopies = 1;
		    this.copiesReferenceFieldInterval = 30;
		}
		'''
	}
	
	
	def CharSequence initializeEnumSlotsWithDefault(Entity entity) {
		'''
		initializeEnumFieldsWithDefault() {
			«entity.slots.filter[isEnum].map[it.initializeSelectedDropDownItem].join»
		}
		'''
	}
	
	def CharSequence initializeSelectedDropDownItem(Slot slot) {
		val enumerarion = slot.asEnum
		var index = -1;
		if (enumerarion.hasDefault) {
			index = enumerarion.defaultIndex
		}
		
		if (index == -1) {
			return ''
		}
		
		'''
		this.«slot.ownerEntity.fieldName».«slot.fieldName» = this.«slot.webDropdownOptions»[«index»].value;
		'''
		
	}
	
	def CharSequence generateSearchCEP(Rule rule) {
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		
		val searchCEP = rule.apply.searchCEPExpression
		val cepField = searchCEP.cepField
		val ufField = searchCEP.ufField
		val localidadeField = searchCEP.localidadeField
		val bairroField = searchCEP.bairroField
		val logradouroField = searchCEP.logradouroField
		val complementoField = searchCEP.complementoField
		val searchCEPService = WebSearchCEPServiceGenerator.SERVICE_CLASS_NAME.toFirstLower
		
		'''
		searchCEP() {
		    let cep = this.«entityVar».«cepField.field.fieldName»;
		    if (cep) {
		      cep = cep.trim().replace('-', '');
		    }
		
		    if (!cep || cep.length !== 8) {
		      this.messageHandler.showError(`CEP '${this.«entityVar».cep}' inválido para busca.`);
		      return;
		    }
		
		    this.«searchCEPService».searchCEP(cep)
		    .then(result => {
		      this.clearSearchCEPData();
		      if (result.erro) {
		        this.messageHandler.showError(`CEP '${this.«entityVar».cep}' não encontrado.`);
		        return;
		      }
		      this.«entityVar».cep = result.cep;
		      const uf = this.«ufField.field.webDropdownOptions».find(it => it.value === result.uf);
		
		      this.«entityVar».«ufField.field.fieldName» = uf ? uf.value : null;
		      this.«entityVar».«localidadeField.field.fieldName» = result.localidade;
		      this.«entityVar».«bairroField.field.fieldName» = result.bairro;
		      this.«entityVar».«logradouroField.field.fieldName» = result.logradouro;
		      this.«entityVar».«complementoField.field.fieldName» = result.complemento;
		    })
		    .catch(e => {
		      this.clearSearchCEPData();
		      this.messageHandler.showError('Erro ao buscar CEP. Verifique se você informou um CEP válido.');
		    });
		
		  }
		
		  clearSearchCEPData() {
		    this.«entityVar».«ufField.field.fieldName» = null;
		    this.«entityVar».«localidadeField.field.fieldName» = null;
		    this.«entityVar».«bairroField.field.fieldName» = null;
		    this.«entityVar».«logradouroField.field.fieldName» = null;
		    this.«entityVar».«complementoField.field.fieldName» = null;
		  }
		'''
	}
	
	def CharSequence generateRuleMakeCopiesActions(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		val referenceField = rule.getRuleMakeCopiesReferenceField
		val refField = '''this.«entityVar».«referenceField.fieldName»'''
		val refFieldName = referenceField.fieldName
		val customServiceVarName = entity.toEntityWebCustomServiceVarName
		
		val helpMethodName = actionName.toString.concat('Help()');
		customActions.add(helpMethodName.concat(': string'));
		
		val hiddeWhen = rule?.apply?.makeCopiesExpression?.hiddeWhen
		var expression = ''
		if (hiddeWhen !== null) {
			val resultStrExp = new StringBuilder
			hiddeWhen.expression.buildRuleWhenExpression(resultStrExp)
			expression = resultStrExp.toString
		}
		
		val grouperFieldText = grouperField?.label ?: grouperField.fieldName.toFirstUpper
		val refFieldText = referenceField?.label ?: refFieldName.toFirstUpper
		
		'''
		
		«IF hiddeWhen !== null»
		«rule.apply.makeCopiesExpression.hiddeWhenMethodName»(): boolean {
			const expression = («expression»);
			return expression;
		}
		
		«ENDIF»
		«helpMethodName»: string {
			return this.«customServiceVarName».«helpMethodName»;
		}
		
		«actionName»(form: FormControl) {
		      if (!this.«entityVar».«grouperField.fieldName») {
		        this.messageHandler.showError('Campo \'«grouperFieldText»\' deve ser informado para gerar cópias.');
		        return;
		      }
		      
		      if (!«refField») {
		        this.messageHandler.showError('Campo \'«refFieldText»\' deve ser informado para gerar cópias.');
		        return;
		      }
		      «customServiceVarName.buildCustomActionBefore(actionName.toString, entity)»
		      // Begin validation for past dates
		      const «refFieldName»FirstCopy = moment(«refField»).add(1, 'month');
		      const today = moment();
		      if («refFieldName»FirstCopy.isBefore(today)) {
				const «refFieldName»FirstCopyStr = «refFieldName»FirstCopy.format('DD/MM/YYYY');
				const «refFieldName»Str = moment(«refField»).format('DD/MM/YYYY');
				this.confirmation.confirm({
				  message: `Baseado na data de «referenceField.label.toFirstLower» da conta atual (<strong>${«refFieldName»Str}</strong>),
				  a primeira cópia da conta terá data de «referenceField.label.toFirstLower» no passado (<strong>${«refFieldName»FirstCopyStr}</strong>).
				  <br>Deseja continuar mesmo assim?`,
				  accept: () => {
				    ///
				    this.«serviceVar».«actionName»(this.«entityVar».«entity.id.fieldName», this.numberOfCopies,
						this.copiesReferenceFieldInterval, this.«entityVar».«grouperField.fieldName»)
				    	.then(() => {
				    		this.messageHandler.showSuccess('Operação realizada com sucesso!');
				    		«customServiceVarName.buildCustomActionAfter(actionName.toString, entity)»
				    	}).
				    	catch(error => {
					    	const message =  JSON.parse(error._body).message || 'Não foi possível realizar a operação';
					    	console.log(error);
					      	this.messageHandler.showError(message);
				  		});
				  }
				});
		      
		      	return;
		      }
		      // End validation
		      this.«serviceVar».«actionName»(this.«entityVar».«entity.id.fieldName», this.numberOfCopies,
		        this.copiesReferenceFieldInterval, this.«entityVar».«grouperField.fieldName»)
			    .then(() => {
		        	this.messageHandler.showSuccess('Operação realizada com sucesso!');
			  		«customServiceVarName.buildCustomActionAfter(actionName.toString, entity)»
			    }).
			    catch(error => {
		        	const message =  JSON.parse(error._body).message || 'Não foi possível realizar a operação';
		        	console.log(error);
			      	this.messageHandler.showError(message);
			  });
		}
		'''
	}
	
	def CharSequence initializeMakeCopiesVars(Rule rule) {
		val referenceField = rule.apply.makeCopiesExpression.referenceField.field
		'''
		 
		numberOfCopies = 1;
		copiesReferenceFieldInterval = 30;
		
		copiesReferenceFieldOptions: SelectItem[];
		copiesReferenceField: SelectItem = { label: '«referenceField.labelValue»', value: '«referenceField.fieldName»' };
		copiesReferenceFieldSelected: SelectItem;
		 
		'''
	}
	
	def CharSequence generateEnumInitializationOptions(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		private «slot.webDropdownOptionsInitializationMethod»() {
		    this.«slot.webDropdownOptions» = [
		    	{ label: 'Selecione um item', value: null },
		    	«enumerarion.items.map['''{ label: this.getTranslation('«slot.translationKey + '_' + it.name.toLowerCase»'), value: '«it.name»' }'''].join(', \r\n')»
		    ];
		}
		  
		'''
	}
	
	def CharSequence mountDropdownOptionsVar(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		«slot.webDropdownOptions»: «enumerarion.toDtoName»[];
		'''
	}
	
	def CharSequence mountAutoCompleteSuggestionsVar(Slot slot) {
		val entity = slot.asEntity
		'''
		«slot.webAutoCompleteSuggestions»: «entity.toAutoCompleteName»[];
		'''
	}
	
	def CharSequence mountAutoComplete(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		
		val serviceName = ownerEntity.toEntityWebServiceClassName.toFirstLower
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id && !(entity.hasEntityVersion && it.name.toLowerCase == 'version')]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		'''
		«slot.toAutoCompleteClearMethodName»(event) {
			// The autoComplete value has been reseted
			this.«ownerEntity.fieldName».«slot.fieldName» = null;
		}
		
		«slot.toAutoCompleteOnBlurMethodName»(event) {
			// Seems a PrimeNG bug, if clear an autocomplete field, on onBlur event, the null value is empty string.
			// Until PrimeNG version: 7.1.3.
			if (String(this.«ownerEntity.fieldName».«slot.fieldName») === '') {
				this.«ownerEntity.fieldName».«slot.fieldName» = null;
			}
		}
		
		«slot.toAutoCompleteName»(event) {
			«IF hasAutoCompleteWithOwnerParams»
			const «ownerEntity.fieldName» = (JSON.parse(JSON.stringify(this.«ownerEntity.fieldName»)));
			if (String(«ownerEntity.fieldName».«slot.fieldName» === '')) {
				«ownerEntity.fieldName».«slot.fieldName» = null;
			}
			«ENDIF»
		    const query = event.query;
		    this.«serviceName»
		      .«slot.toSlotAutoCompleteName»(query«IF hasAutoCompleteWithOwnerParams», «ownerEntity.fieldName»«ENDIF»)
		      .then((result) => {
		        this.«slot.webAutoCompleteSuggestions» = result as «entity.toAutoCompleteName»[];
		      })
		      .catch(error => {
		        this.messageHandler.showError(error);
		      });
		}
		
		«IF !resultSlots.isEmpty»
		«slot.webAutoCompleteFieldConverter»(«slot.fieldName»: «entity.toAutoCompleteName») {
			let text = '';
			if («slot.fieldName») {
				«resultSlots.map[slot.resolveAutocompleteFieldNameForWeb(it).buildAutoCompleteFieldConverter(slot.getAutocompleteFieldNameForWeb(it))].join()»
			}
			
			if (text === '') {
				text = null;
			}
			return text;
		}
		«ENDIF»
		'''
	}
	
	def CharSequence buildAutoCompleteFieldConverter(String resolvedFieldName, String fieldName) {
		'''
		if («fieldName») {
		    if (text !== '') {
		      text += ' - ';
		    }
		    text += «resolvedFieldName»; 
		}
		
		'''
	}
	
	def CharSequence mountServiceConstructorInject(Slot slot) {
		val serviceName = slot.asEntity.toEntityWebServiceClassName
		'''
		private «serviceName.toFirstLower»: «serviceName»,
		'''
	}
	
	def void initializeImports(Entity entity) {
		imports.add('''
		import { Component, OnInit } from '@angular/core';
		import { FormControl, FormGroup } from '@angular/forms';
		import { ActivatedRoute, Router } from '@angular/router';
		import {MessageService} from 'primeng/api';
		''')
	}
	
	
}