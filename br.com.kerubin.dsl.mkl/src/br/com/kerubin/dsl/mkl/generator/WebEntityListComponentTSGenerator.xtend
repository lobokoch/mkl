package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt
import java.util.Map.Entry

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*
import java.util.LinkedHashSet

class WebEntityListComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	
	val LinkedHashSet<String> customActions = newLinkedHashSet
	val LinkedHashSet<String> customActionsImport = newLinkedHashSet
	
	val periodItems = newLinkedHashMap(
		'Minha competência' -> '12',
		'Hoje' -> '0',
		'Amanhã' -> '1',
		'Esta semana' -> '2',
		'Semana que vem' -> '3',
		'Este mês' -> '4',
		'Mês que vem' -> '5',
		'Este ano' -> '6',
		'Ano que vem' -> '7',
		'Ontem' -> '8',
		'Semana passada' -> '9',
		'Mês passado' -> '10',
		'Ano passado' -> '11',
		'Personalizado' -> '99'
	)
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[ entity |
			entity.generateComponentTS
		]
	}
	
	def generateComponentTS(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebListComponentName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityComponentTS)
		
		if (entity.enableWebCustomListService) {
			val fileName = path + entity.toEntityWebListCustomServiceFileName + '.ts'
			generateFile(fileName, entity.doGenerateEntityTSListCustomService)
		}
	}
	
	def CharSequence doGenerateEntityTSListCustomService(Entity entity) {
		val customServiceName = entity.toEntityWebCustomListServiceClassName
		
		val component = entity.toEntityWebListComponentName
		val componentClassName = entity.toEntityWebListClassName
		
		'''
		import { «componentClassName» } from './«component»';
		import { Injectable } from '@angular/core';
		
		«customActionsImport.map[it].join»
		
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
		} else if (methodDef.endsWith(': String')) {
			returnValue = 'return null'
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
	
	def CharSequence doGenerateEntityComponentTS(Entity entity) {
		imports = new StringConcatenationExt()
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		val listFilterNameVar = entity.toEntityListFilterName
		
		val entitySumFieldsClassName = entity.toEntitySumFieldsName
		val getMethodEntitySumFields = 'get' + entitySumFieldsClassName
		
		val filterSlots = entity.slots.filter[it.hasListFilter]
		
		val ruleActions = entity.ruleActions
		val rulesPolling = entity.ruleFormListPolling
		
		val idVar = entity.id.name.toFirstLower
		
		val rulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD
		
		val customListServiceName = entity.toEntityWebCustomListServiceClassName
		val customListServiceVar = entity.toEntityWebCustomListServiceVarName
		
		imports.add('''
		import { Component, OnInit } from '@angular/core';
		import {ConfirmationService, LazyLoadEvent, SelectItem} from 'primeng/api';
		import { Dropdown } from 'primeng/dropdown';
		import * as moment from 'moment';
		import { MessageHandlerService } from 'src/app/core/message-handler.service';
		''')
		
		imports.add('''import { «serviceName» } from './«entity.toEntityWebServiceName»';''')
		imports.add('''import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';''')
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { «entity.toEntityListFilterClassName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { SortField } from './«entity.toEntityWebModelName»';''')
		
		entity.slots.filter[it.isListFilterMany].forEach[
			imports.add('''import { «it.toAutoCompleteClassName» } from './«entity.toEntityWebModelName»';''')
		]
		
		filterSlots.filter[it.isEqualTo && it.isEnum].forEach[
			val slotAsEnum = it.asEnum
			imports.newLine
			imports.add('''import { «slotAsEnum.toDtoName» } from '«service.serviceWebEnumsPathName»';''')
		]
		
		entity.slots.filter[it.isEntity].forEach[
			val slotAsEntity = it.asEntity
			imports.newLine
			//imports.add('''import { «slotAsEntity.toEntityWebServiceClassName» } from './«slotAsEntity.toEntityWebServiceNameWithPath»';''')
			//imports.add('''import { «slotAsEntity.toDtoName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
			imports.add('''import { «slotAsEntity.toAutoCompleteName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
		]
		
		if (entity.hasSumFields) {
			imports.add('''import { «entitySumFieldsClassName» } from './«entity.toEntityWebModelName»';''')
		}
		
		if (entity.enableWebCustomListService) {
			imports.add('''import { «customListServiceName» } from './custom-list-«webName».service';''')
		}
		
		val component = entity.toEntityWebListComponentName
		
		val sortFields = entity.sortFields
		val rulesGridColumns = entity.getRulesGridColumns
		val rulesGridWithAddColumn = entity.getRulesGridWithAddColumn
		
		val body = '''
		
		@Component({
		  selector: '«entity.toEntityWebListAppComponentName»',
		  templateUrl: './«component».html',
		  styleUrls: ['./«component».css']
		})
		
		export class «entity.toEntityWebListClassName» implements OnInit {
			tableLoading = false;
			
			«entity.toEntityWebListItems»: «dtoName»[];
			«entity.toEntityWebListItemsTotalElements» = 0;
			«listFilterNameVar» = new «listFilterNameVar.toFirstUpper»();
			
			«IF !filterSlots.empty»
			«filterSlots.generateFilterSlotsInitializationVars»
			dateFilterIntervalDropdownItems: SelectItem[];
			«ENDIF»
			
			
			«IF entity.hasSumFields»
			«entitySumFieldsClassName.toFirstLower» = new «entitySumFieldsClassName»();
			«ENDIF»
			«IF !rulesPolling.empty»
			«rulesPolling.generatePollingVars»
			«ENDIF»
			
			constructor(
			    private «serviceVar»: «serviceName»,
			    «IF entity.enableWebCustomListService»
			    private «customListServiceVar»: «customListServiceName»,
			    «ENDIF»
			    private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»,
			    private confirmation: ConfirmationService,
			    private messageHandler: MessageHandlerService
			) { 
				«IF entity.enableWebCustomService»
				this.«customListServiceVar».setComponent(this);
				«ENDIF»
			}
			
			ngOnInit() {
				«filterSlots.filter[it.isBetween && it.isDate].map['''this.«toIsBetweenOptionsOnClickMethod»(null);'''].join('\r\n')»
				«IF !filterSlots.filter[it.isBetween && it.isDate].empty»
				this.initializeDateFilterIntervalDropdownItems();
				«ENDIF»
				«IF !filterSlots.empty»
				«filterSlots.generateFilterSlotsInitialization»
				«ENDIF»
			}
			
			«entity.toEntityListListMethod»(pageNumber = 0) {
				this.tableLoading = true;
			    this.«listFilterNameVar».pageNumber = pageNumber;
			    this.«serviceVar»
			    .«entity.toEntityListListMethod»(this.«listFilterNameVar»)
			    .then(result => {
			    	try {
				      	this.«entity.toEntityWebListItems» = result.items;
				      	this.«entity.toEntityWebListItemsTotalElements» = result.totalElements;
				      
						«IF entity.hasSumFields»
						this.«getMethodEntitySumFields»();
						«ENDIF»
					} finally {
						this.tableLoading = false;
					}
			    })
			    .catch(e => {
			    	this.tableLoading = false;
			    });
				
			}
			
			«IF entity.hasSumFields»
			«getMethodEntitySumFields»() {
				this.tableLoading = true;
			    this.«serviceVar».«getMethodEntitySumFields»(this.«listFilterNameVar»)
				.then(response => {
					try {
						this.«entitySumFieldsClassName.toFirstLower» = response;
					} finally {
						this.tableLoading = false;
					}
				})
				.catch(e => {
					this.tableLoading = false;
					this.messageHandler.showError(e);
				});
			}
			«ENDIF»
			
			«entity.toWebEntityFilterSearchMethod» {
			    this.«entity.toEntityListListMethod»(0);
			}
			
			delete«dtoName»(«fieldName»: «dtoName») {
			    this.confirmation.confirm({
			      message: 'Confirma a exclusão do registro?',
			      accept: () => {
			        this.«serviceVar».delete(«fieldName».«idVar»)
			        .then(() => {
			          this.messageHandler.showSuccess('Registro excluído!');
			          this.«entity.toEntityListListMethod»(0);
			        })
			        .catch((e) => {
			          this.messageHandler.showError(e);
			        });
			      }
			    });
			}
			
			«entity.toEntityListOnLazyLoadMethod»(event: LazyLoadEvent) {
			    if (event.multiSortMeta) {
			      this.«listFilterNameVar».sortFields = new Array(event.multiSortMeta.length);
			      event.multiSortMeta.forEach(sortField => {
			      	this.«listFilterNameVar».sortFields.push(new SortField(sortField.field, sortField.order));
			      });
			    } else {
			    	«IF !sortFields.empty»
			    	this.«listFilterNameVar».sortFields = new Array(«sortFields.size»);
			    	«sortFields.map[it |
			    	'''
			    	this.«listFilterNameVar».sortFields.push(new SortField('«it.fieldName»', «it.sort.orderVal»));
			    	'''
			    	].join»
			    	«ELSE»
			    	this.«listFilterNameVar».sortFields = new Array(1);
			    	this.«listFilterNameVar».sortFields.push(new SortField('«entity.defaultSortField»', «entity.defaultSortFieldOrderBy»)); // asc
			    	«ENDIF»
			    }
			    const pageNumber = event.first / event.rows;
			    this.«listFilterNameVar».pageSize = event.rows;
			    this.«entity.toEntityListListMethod»(pageNumber);
			}
			
			«filterSlots.filter[isListFilterMany].map[generateAutoCompleteMethod].join»
			
			«filterSlots.filter[it.isEqualTo && it.isEnum].map[it.generateEnumInitializationOptions].join»
			
			«entity.slots.filter[isEntity].map[generateAutoCompleteFieldConverter].join»
			
			«IF !filterSlots.filter[it.isBetween && it.isDate].empty»
			private initializeDateFilterIntervalDropdownItems() {
				this.dateFilterIntervalDropdownItems = [
				    «periodItems.entrySet.map[it.gerarPeriodo].join(',\r\n')»
				  ];
			}
			
			«filterSlots.filter[it.isBetween && it.isDate].map[generatePeriodIntervalSelectMethod].join»
			«ENDIF»
			
			«IF entity.hasRules»
			«entity.buildRulesForGridRowStyleClass»
			«ENDIF»
			«IF !rulesGridColumns.empty»
			«rulesGridColumns.buildRulesGridColumns»
			«ENDIF»
			«IF !rulesGridWithAddColumn.empty»
			«rulesGridWithAddColumn.map[buildRuleGridWithAddColumn].join»
			«ENDIF»
			«ruleActions.map[generateRuleActions].join»
			
			«buildTranslationMethod(service)»
			
			«IF entity.slots.exists[it.isGridShowNumberAsNegative]»
			
			doShowNumberAsNegative(value: any) {
			    if (value) {
			      return value * -1;
			    }
			    return value;
			  }
			  
			«ENDIF»
			
			«IF !rulesFormWithDisableCUD.empty»
			«rulesFormWithDisableCUD.head.generateRuleFormWithDisableCUD»
			«ENDIF»
			«IF !rulesPolling.empty»
			«rulesPolling.generatePollingMethodsFormList»
			«ENDIF»
		}
		'''
		
		val source = imports.ln.toString + body
		source
	}
	
	def CharSequence gerarPeriodo(Entry<String, String> entry) {
		'''{label: '«entry.key»', value: '«entry.value»'}'''
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
	
	def CharSequence generateRuleFormWithDisableCUD(Rule rule) {
		val entity = rule.ruleOwnerEntity
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		
		val methodName = entity.toRuleFormWithDisableCUDMethodName
		
		val hasWhen = rule.hasWhen
		var String expression = 'false'
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp, false)
			expression = resultStrExp.toString
		}
		
		
		'''
		«methodName»(«fieldName»: «dtoName») {
			const expression = «expression»;
			return expression;
			
		}
		'''
	}
	
	def CharSequence generateRuleActions(Rule rule) {
		val actionName = rule.getRuleActionName 
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val dtoName = entity.toDtoName
		val idVar = entity.id.name.toFirstLower
		
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		val hasWhen = rule.hasWhen
		var String expression = null
		if (hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpression(resultStrExp, false)
			expression = resultStrExp.toString
		}
		
		'''
		«IF hasWhen»
		
		«rule.getRuleActionWhenName»(«entityVar»: «dtoName») {
			return «expression»;
		}
		«ENDIF»
		
		«actionName»(«entityVar»: «dtoName») {
			this.«serviceVar».«actionName»(«entityVar».«idVar»)
				.then(() => {
				  this.messageHandler.showSuccess('Ação executada com sucesso!');
				  this.«entity.toEntityListListMethod»(0);
				})
				.catch((e) => {
					console.log('Erro ao executar a ação «actionName»: ' + e);
				  	this.messageHandler.showError('Não foi possível executar a ação.');
				});
		}
		'''
	}
	
	def CharSequence buildRulesForGridRowStyleClass(Entity entity) {
		val rules = entity.rulesWithTargetEnum.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ROWS && it.apply.hasStyleClass]
		
		if (!rules.empty) {
			val entityVar = entity.fieldName
			'''
			applyAndGetRuleGridRowStyleClass(«entityVar»: «entity.toDtoName»): String {
				«rules.map[buildRuleForGridRowStyleClass].join»
			
			    return null;
			}
			'''
		}
	}
	
	def CharSequence buildRulesGridColumns(Iterable<Rule> ruls) {
		
		val entity = ruls.head.entity
		val dtoName = entity.toEntityDTOName
		
		val entityVar = entity.fieldName
		
		val customListService = entity.toEntityWebCustomListServiceVarName
		customActionsImport.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		val groups = ruls.groupBy[ruleAsRuleTargetEnum.group]
		
		groups.entrySet.map[it |
		val rules = it.value
		val group = it.key
		val methodNameDef = '''«group.toRuleGridColumnsApplyStyleClassMethodName»(«entityVar»: «entity.toDtoName»): String'''
		val methodNameCall = '''«group.toRuleGridColumnsApplyStyleClassMethodName»(«entityVar»)'''
		
		customActions.add(methodNameDef);
		
		'''
				
		«methodNameDef» {
			const result = this.«customListService».«methodNameCall»;
			if(result) {
				return result === '' ? null : result;
			}
			
			«rules.map[buildRuleWhenExpression].join»
		
		    return null;
		}
		'''
		].join
	}
	
	def CharSequence buildRuleGridWithAddColumn(Rule rule) {
		val entity = rule.entity
		
		val entityVar = entity.fieldName
		val fieldName = rule.apply.addColumnExpression.name
		val customListService = entity.toEntityWebCustomListServiceVarName
		val dtoName = entity.toEntityDTOName
		
		//tem que ter um método GET VALUE, e fazer import da classe da entidade conta no custom list serve.
		val addColumnMethodNameCall = '''«fieldName.toRuleAddColumnGetValueMethodName»(«entityVar»)'''
		val addColumnMethodNameDef = '''«fieldName.toRuleAddColumnGetValueMethodName»(«entityVar»: «dtoName»)'''
		customActions.add(addColumnMethodNameDef.concat(': String'));
		customActionsImport.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		
		'''
				
		«fieldName.toRuleAddColumnGetValueMethodName»(«entityVar»: «entity.toDtoName»): String {
			
		    return this.«customListService».«addColumnMethodNameCall»;
		    
		}
		'''
	}
	
	
	def CharSequence buildRuleWhenExpression(Rule rule) {
		val resultStrExp = new StringBuilder
		rule.when.expression.buildRuleWhenExpression(resultStrExp, false)
		val exp = resultStrExp.toString
		'''
		
		if («exp») {
			return '«rule.apply.getResutValue»';
		}
		'''
	}
	
	def CharSequence buildRuleForGridRowStyleClass(Rule rule) {
		val resultStrExp = new StringBuilder
		rule.when.expression.buildRuleWhenForGridRowStyleClass(resultStrExp, false)
		val exp = resultStrExp.toString
		'''
		
		if («exp») {
			return '«rule.apply.getResutValue»';
		}
		'''
	}
	
	/*
	// DEPRECADO, mudei para usar o método geral, só testar e se tudo deu certo, pode remover esse método.
	def void buildRuleWhenForGridRowStyleClass(RuleWhenExpression expression, StringBuilder resultStrExp) {
		
		
		if (expression ===  null) {
			return
		}
		
		var String objName = null
		var String strExpression = null
		var isObjStr = false
		var isObjDate = false
		var isNumber = false
		if (expression.left.whenObject instanceof FieldObject) {
			val slot = (expression.left.whenObject as FieldObject).getField
			objName = slot.ownerEntity.fieldName + '.' + slot.fieldName
			isObjStr = slot.isString
			isObjDate = slot.isDate
			isNumber = slot.isNumber
			strExpression = objName
		}
		else if (expression.left.whenObject instanceof TemporalObject) {
			val tObj = expression.left.whenObject as TemporalObject
			objName = tObj.temporalConstant.literal
			strExpression = tObj.temporalConstant.getTemporalConstantValue
			isObjDate = true
		}
		else if (expression.left.whenObject instanceof NumberObject) {
			val tObj = expression.left.whenObject as NumberObject
			objName = tObj.value.toString
			strExpression = objName
			isNumber = true
		}
		val op = expression.left.objectOperation
		if (op !== null) {
			if (op instanceof RuleWhenOpIsNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append('!').append(objName).concatSB('||').concatSB(objName).append('.trim().length == 0)')						
				}
				else {
					resultStrExp.concatSB('!').append(objName)					
				}
			}
			else if (op instanceof RuleWhenOpIsNotNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append(objName).concatSB('||').concatSB(objName).append('.trim().length > 0)')						
				}
				else {
					resultStrExp.concatSB(objName)					
				}
			}
			else if (op instanceof RuleWhenOpIsBetween) {
				val opIsBetween = op as RuleWhenOpIsBetween
				val dateFrom = opIsBetween.betweenFrom.getTemporalValue
				val dateTo = opIsBetween.betweenTo.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isBetween(«dateFrom», «dateTo»)''')
				}
				else {
					resultStrExp.concatSB('''(«objName» >= «dateFrom» && «objName» <= «dateTo»)''')					
				}
			}
			else if (op instanceof RuleWhenOpIsSame) {
				val opIsSame = op as RuleWhenOpIsSame
				val value = opIsSame.valueToCompare.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isSame(«value», 'day')''')
				}
				else {
					resultStrExp.concatSB('''«objName» == «value»''')					
				}
			}
			else if (op instanceof RuleWhenOpIsBefore) {
				val opIsBefore = op as RuleWhenOpIsBefore
				val value = opIsBefore.valueToCompare.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isBefore(«value», 'day')''')
				}
				else {
					resultStrExp.concatSB('''«objName» < «value»''')					
				}
			}
		}
		else {
			resultStrExp.concatSB(strExpression)
		}
		
		if (expression.rigth !== null) {
			resultStrExp.concatSB(expression.operator.adaptRuleWhenOperator)
			expression.rigth.buildRuleWhenForGridRowStyleClass(resultStrExp)
		}
	}*/
	
	/*def private StringBuilder insertSB(StringBuilder sb, String value) {
		if (sb.length > 0) {
			sb.append(' ')
		}
		sb.append(value);
	}
	
	def private String adaptRuleWhenOperator(RuleWhenOperator operator) {
		val opValue = operator.operator
		switch (opValue) {
			case 'and': {
				'&&'
			}
			case 'or': {
				'||'
			}
			default: {
				opValue
			}
		}
	}
	
	def private String getGetTemporalValue(RuleWhenTemporalValue temporalValue) {
		if (temporalValue.temporalObject !== null) {
			val tempObj = temporalValue.temporalObject
			if (tempObj.temporalFuncation !== null) {
				val tempFunc = tempObj.temporalFuncation.getTemporalFuncationValue
				tempFunc
			}
			else {
				val constObj = tempObj.temporalConstant.getTemporalConstantValue
				constObj
			}
		}
		else {
			temporalValue.valueInt.toString
		}
	}
	
	def private String toDateMoment(String objectName) {
		'moment(' + objectName + ')'
	}
	
	def private String getTemporalFuncationValue(TemporalFunction tf) {
		var result = '<INVALID_TEMPORAL_FUNCTION>'
		if (tf instanceof TemporalFunctionNextDays) {
			val func = tf as TemporalFunctionNextDays
			val days = func.days
			result = "moment().add(" + days + ", 'day')"
		}
		result
		
	}
	
	def private  String getTemporalConstantValue(RuleWhenTemporalConstants tc) {
		switch (tc) {
			case RuleWhenTemporalConstants.TOMORROW: {
				"moment().add(1, 'day')"
			}
			case RuleWhenTemporalConstants.YESTERDAY: {
				"moment().add(-1, 'day')"
			}
			case RuleWhenTemporalConstants.END_OF_WEEK: {
				"moment().endOf('week')"
			}
			default: {
				'moment()' // Today
			}
		}
	}*/
		
	def CharSequence generateAutoCompleteMethod(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		«slot.webAutoCompleteMethod»(event) {
		    const query = event.query;
		    this.«entity.toEntityWebServiceClassName.toFirstLower».«slot.webAutoCompleteMethod»(query)
		    .then((result) => {
		      this.«slot.webAutoCompleteSuggestions» = result;
		    })
		    .catch(erro => {
		      this.messageHandler.showError('Erro ao buscar registros com o termo: ' + query);
		    });
		}
		
		'''
	}
	
	def CharSequence generateAutoCompleteFieldConverter(Slot slot) {
		val entity = slot.asEntity
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && !it.isHiddenSlot]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		'''
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
	
	def CharSequence generatePeriodIntervalSelectMethod(Slot slot) {
		val entity = slot.ownerEntity
		val listFilterName = entity.toEntityListFilterName
		'''
		
		«slot.toIsBetweenOptionsOnClickMethod»(dropdown: Dropdown) {
			this.«listFilterName».«slot.toIsBetweenFromName» = null;
			this.«listFilterName».«slot.toIsBetweenToName» = null;
			
			let dateFrom = null;
			let dateTo = null;
		
			const valor = Number(this.«slot.toIsBetweenOptionsSelected».value);
			switch (valor) {
				case 0: // Hoje
					dateFrom = moment();
					dateTo = moment();
					break;
					//
				case 1: // Amanhã
					dateFrom = moment().add(1, 'day');
					dateTo = moment().add(1, 'day');
					break;
					//
				case 2: // Esta semana
					dateFrom = moment().startOf('week');
					dateTo = moment().endOf('week');
					break;
					//
				case 3: // Semana que vem
					dateFrom = moment().add(1, 'week').startOf('week');
					dateTo = moment().add(1, 'week').endOf('week');
					break;
					//
				case 4: // Este mês
					dateFrom = moment().startOf('month');
					dateTo = moment().endOf('month');
					break;
					//
				case 5: // Mês que vem
					dateFrom = moment().add(1, 'month').startOf('month');
					dateTo = moment().add(1, 'month').endOf('month');
					break;
					//
				case 6: // Este ano
					dateFrom = moment().startOf('year');
					dateTo = moment().endOf('year');
					break;
					//
				case 7: // Ano que vem
					dateFrom = moment().add(1, 'year').startOf('year');
					dateTo = moment().add(1, 'year').endOf('year');
					break;
					// Passado
				case 8: // Ontem
					dateFrom = moment().add(-1, 'day');
					dateTo = moment().add(-1, 'day');
					break;
					//
				case 9: // Semana passada
					dateFrom = moment().add(-1, 'week').startOf('week');
					dateTo = moment().add(-1, 'week').endOf('week');
					break;
					//
				case 10: // Mês passado
					dateFrom = moment().add(-1, 'month').startOf('month');
					dateTo = moment().add(-1, 'month').endOf('month');
					break;
					//
				case 11: // Ano passado
					dateFrom = moment().add(-1, 'year').startOf('year');
					dateTo = moment().add(-1, 'year').endOf('year');
					break;
					
				case 12: // Minha competência
					dateFrom = moment().startOf('month');
					dateTo = moment().endOf('month').add(5, 'day'); // Five days after and of the month
					break;
				
				default:
					break;
			} // switch
		
			if (dateFrom != null) {
			  this.«listFilterName».«slot.toIsBetweenFromName» = dateFrom.toDate();
			}
			
			if (dateTo != null) {
			  this.«listFilterName».«slot.toIsBetweenToName» = dateTo.toDate();
			}
			
			if (dateFrom != null && dateTo != null) {
			  // this.«entity.toEntityListListMethod»(0);
			}
		}
		'''
	}
	
	def CharSequence generateFilterSlotsInitializationVars(Iterable<Slot> slots) {
		'''
		«slots.map[generateFilterSlotInitializationVars].join»
		'''
	}
	
	def CharSequence generateFilterSlotInitializationVars(Slot slot) {
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween
		
		val isEqualTo = slot.isEqualTo
		
		var defVal = "{label: 'Minha competência', value: '12'}";
		if (slot.hasListFilter) {
			val key = slot.listFilter.filterOperator?.^default
			if (key !== null) {
				val entry = periodItems.entrySet.findFirst[it | it.key == key || it.value == key]
				if (entry !== null) {
					defVal = '''{label: '«entry.key»', value: '«entry.value»'}''';
				}
			}
		}
			
		'''
		«IF isEqualTo && slot.isEnum»
		«slot.mountDropdownOptionsVar»
		«ENDIF»
		«IF isMany»
		«slot.webAutoCompleteSuggestions»: «slot.toAutoCompleteClassName»[];
		«ELSEIF isNotNull || isNull»
		
		«IF isNotNull»
		«ENDIF»
		
		«IF isNull»
		«ENDIF»
		
		«ELSEIF isBetween»
		
		«IF slot.isDate»
		«slot.toIsBetweenOptionsSelected»: SelectItem = «defVal»;
		«ELSE»
		«ENDIF»
		
		«ENDIF»
		'''
	}
	
	def CharSequence generateFilterSlotsInitialization(Iterable<Slot> slots) {
		'''
		«slots.map[generateFilterSlotInitialization].join»
		'''
	}
	
	def CharSequence generateFilterSlotInitialization(Slot slot) {
		val entity = slot.ownerEntity
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween
		
		val isEqualTo = slot.isEqualTo
			
		'''
		«IF isEqualTo && slot.isEnum»
		this.«slot.webDropdownOptionsInitializationMethod»();
		«ENDIF»
		«IF isMany»
		«ELSEIF isNotNull || isNull»
		
		«IF isNotNull»
		this.«entity.toEntityListFilterName».«slot.isNotNullFieldName» = «IF slot.getIsNotNull_isNullSelected === 0»true;«ELSE»false;«ENDIF»
		«ENDIF»
		
		«IF isNull»
		this.«entity.toEntityListFilterName».«slot.isNullFieldName» = «IF slot.getIsNotNull_isNullSelected === 1»true;«ELSE»false;«ENDIF»
		«ENDIF»
		
		«ELSEIF isBetween»
		
		«IF slot.isDate»
		«ELSE»
		«ENDIF»
		
		«ENDIF»
		'''
	}
	
	def CharSequence addExtras() {
		'''
		/*********************
		getContaCssClass(conta: ContaPagar): string {
		    const vencimento = conta.dataVencimento;
		    const emAberto = conta.dataPagamento == null;
		    const hoje = moment();
		    if (vencimento && emAberto) {
		      if (moment(vencimento).isBefore(hoje, 'day')) {
		        return 'conta-vencida';
		      }
		      if (moment(vencimento).isSame(hoje, 'day')) {
		        return 'conta-vence-hoje';
		      }
		      if (moment(vencimento).isSame(moment().add(1, 'day'), 'day')) {
		        return 'conta-vence-amanha';
		      }
		      if (moment(vencimento).isBefore(moment().add(1, 'week').startOf('week'), 'day')) {
		        return 'conta-vence-essa-semana';
		      }
		    }
		    return 'conta-ok';
		}
		
		get getTotalGeralContasPagar(): number {
		    const total = this.totaisFiltroContaPagar.totalValorPagar - this.totaisFiltroContaPagar.totalValorPago;
		    return total ? total : 0.0;
		}
		  
		get getTotalValorPagar(): number {
		    const total = this.totaisFiltroContaPagar.totalValorPagar;
		    return total ? total : 0.0;
		}
		
		get getTotalValorPago(): number {
			const total = this.totaisFiltroContaPagar.totalValorPago;
			return total ? total : 0.0;
		}
		
		getTotaisFiltroContaPagar() {
		    this.contasPagarService.getTotaisFiltroContaPagar(this.contaPagarListFilter)
		    .then(response => {
		      this.totaisFiltroContaPagar = response;
		    })
		    .catch(erro => {
		      this.messageHandler.showError('Erro ao buscar totais:' + erro);
		    });
		}
		
		mostrarPagarConta(conta: ContaPagar) {
		    this.contaPagar = new ContaPagar();
		    this.contaPagar.assign(conta);
		    // this.contaPagar.dataPagamento = new Date(this.contaPagar.dataPagamento);
		    const data = this.contaPagar.dataPagamento;
		    if (data == null) {
		      this.contaPagar.dataPagamento = moment().toDate();
		    } else {
		      this.contaPagar.dataPagamento = moment(this.contaPagar.dataPagamento).toDate();
		    }
		    if (!this.contaPagar.valorPago || this.contaPagar.valorPago === 0) {
		      this.contaPagar.valorPago = conta.valor;
		    }
		    this.mostrarDialogPagarConta = true;
		}
		
		cancelarPagarConta() {
			this.mostrarDialogPagarConta = false;
		}
		
		executarPagarConta() {
		    this.contasPagarService.update(this.contaPagar)
		    .then((contaPagar) => {
		      this.mostrarDialogPagarConta = false;
		      this.messageHandler.showSuccess(`A conta ${contaPagar.descricao} foi paga.`);
		      this.contaPagarList(0);
		    })
		    .catch(erro => {
		      this.messageHandler.showError('Erro ao pagar a conta: ' + erro);
		    });
		}
		*********************/
		'''
	}
	
	
}