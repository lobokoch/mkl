package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*
import br.com.kerubin.dsl.mkl.model.Rule
import java.util.Set
import java.util.LinkedHashSet

class WebEntityCRUDComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	val LinkedHashSet<String> importsSet = newLinkedHashSet
	
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
	}
	
	def CharSequence doGenerateEntityTSComponent(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		val ruleMakeCopies = entity.ruleMakeCopies
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val rulesFormOnUpdate = entity.rulesFormOnUpdate
		val rulesFormOnInit = entity.rulesFormOnInit
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { «serviceName» } from './«webName».service';''')
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
			imports.add('''import {SelectItem} from 'primeng/api';''')
		}
		
		val component = entity.toEntityWebCRUDComponentName
		val body = '''
		
		@Component({
		  selector: 'app-«component»',
		  templateUrl: './«component».html',
		  styleUrls: ['./«component».css']
		})
		
		export class «entity.toEntityWebComponentClassName» implements OnInit {
			«IF !ruleMakeCopies.empty»«initializeMakeCopiesVars(ruleMakeCopies.head)»«ENDIF»
			«fieldName» = new «dtoName»();
			«entity.slots.filter[isEntity].map[mountAutoCompleteSuggestionsVar].join('\n\r')»
			«entity.slots.filter[isEnum].map[mountDropdownOptionsVar].join('\n\r')»
			«IF entity.isEnableReplication»«entity.entityReplicationQuantity» = 1;«ENDIF»
			
			constructor(
			    private «serviceVar»: «serviceName»,
			    private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»,
			    «entity.slots.filter[isEntity && it.asEntity.isNotSameName(entity)].map[mountServiceConstructorInject].join('\n\r')»
			    private route: ActivatedRoute,
			    private messageService: MessageService
			) { 
				«entity.slots.filter[isEnum].map['''this.«it.webDropdownOptionsInitializationMethod»();'''].join('\n\r')»
				«IF !ruleMakeCopies.empty»
				this.initializeCopiesReferenceFieldOptions();
				«ENDIF»
			}
			
			ngOnInit() {
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
			}
			
			begin(form: FormControl) {
			    form.reset();
			    setTimeout(function() {
			      this.«fieldName» = new «dtoName»();
			      «IF !rulesFormOnInit.empty»
			      this.rulesOnInit();
	  			  «ENDIF»
			      «IF entity.hasEnumSlotsWithDefault»
			      this.initializeEnumFieldsWithDefault();
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
				    
			    if (this.isEditing) {
			      this.update();
			    } else {
			      this.create();
			    }
				«IF !ruleMakeCopies.empty»
				this.initializeCopiesReferenceFieldOptions();
				«ENDIF»
			}
			
			create() {
				«IF !rulesFormOnCreate.empty»
				this.rulesOnCreate();
				«ENDIF»
				
			    this.«serviceVar».create(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.showSuccess('Registro criado com sucesso!');
			    }).
			    catch(error => {
			      this.showError('Erro ao criar registro: ' + error);
			    });
			}
			
			update() {
				«IF !rulesFormOnUpdate.empty»
				this.rulesOnUpdate();
				
				«ENDIF»
			    this.«serviceVar».update(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.showSuccess('Registro alterado!');
			    })
			    .catch(error => {
			      this.showError('Erro ao atualizar registro: ' + error);
			    });
			}
			
			get«dtoName»ById(id: string) {
			    this.«serviceVar».retrieve(id)
			    .then((«fieldName») => this.«fieldName» = «fieldName»)
			    .catch(error => {
			      this.showError('Erro ao buscar registro: ' + id);
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
			        this.showSuccess('Os registros foram criados com sucesso.');
			      } else {
			        this.showError('Não foi possível criar os registros.');
			      }
			    })
			    .catch(error => {
			      this.showError('Ocorreu um erro ao criar os registros: ' + error);
			    });
			  }
			«ENDIF»
			
			«entity.slots.filter[isEntity].map[mountAutoComplete].join('\n\r')»
			
			«entity.slots.filter[isEnum].map[it.generateEnumInitializationOptions].join»
			
			public showSuccess(msg: string) {
			    this.messageService.add({severity: 'success', summary: 'Successo', detail: msg});
			}
			
			public showError(msg: string) {
			    this.messageService.add({severity: 'error', summary: 'Erro', detail: msg});
			}
			
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
		}
		'''
		
		val source = imports.ln.toString /*+ importsSet.join('\r\n')*/ + '\r\n' + body
		source
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
		      this.showSuccess('Operação executada com sucesso.');
		    })
		    .catch(error => {
		      this.showError('Erro ao executar a operação: ' + error);
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
	
	def CharSequence generateRuleMakeCopiesActions(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		'''
		
		«actionName»(form: FormControl) {
		      if (!this.«entityVar».«grouperField.fieldName») {
		        // this.copiesMustHaveGroup = true;
		        this.showError('Campo \'«grouperField.fieldName.toFirstUpper»\' deve ser informado para gerar cópias.');
		        return;
		      }
		      // this.copiesMustHaveGroup = false;
		
		      this.«serviceVar».«actionName»(this.«entityVar».«entity.id.fieldName», this.numberOfCopies,
		        this.copiesReferenceFieldInterval, this.«entityVar».«grouperField.fieldName»)
			    .then(() => {
		        // this.copiesMustHaveGroup = false;
		        this.showSuccess('Operação realizada com sucesso!');
			    }).
			    catch(error => {
		        // this.copiesMustHaveGroup = false;
		        const message =  JSON.parse(error._body).message || 'Não foi possível realizar a operação';
		        console.log(error);
			      this.showError('Erro: ' + message);
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
		val serviceName = entity.toEntityWebServiceClassName.toFirstLower
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id && !(entity.enableVersion && it.name.toLowerCase == 'version')]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		'''
		«slot.toAutoCompleteClearMethodName»(event) {
			// The autoComplete value has been reseted
			this.«slot.ownerEntity.fieldName».«slot.fieldName» = null;
		}
		
		«slot.toAutoCompleteName»(event) {
		    const query = event.query;
		    this.«serviceName»
		      .autoComplete(query)
		      .then((result) => {
		        this.«slot.webAutoCompleteSuggestions» = result as «entity.toAutoCompleteName»[];
		      })
		      .catch(error => {
		        this.showError('Erro ao buscar registros com o termo: ' + query);
		      });
		}
		
		«IF !resultSlots.isEmpty»
		«slot.webAutoCompleteFieldConverter»(«slot.fieldName»: «entity.toAutoCompleteName») {
			if («slot.fieldName») {
				return «resultSlots.map['''(«slot.resolveAutocompleteFieldNameForWeb(it)» || '<nulo>')'''].join(" + ' - ' + ")»;
			} else {
				return null;
			}
		}
		«ENDIF»
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