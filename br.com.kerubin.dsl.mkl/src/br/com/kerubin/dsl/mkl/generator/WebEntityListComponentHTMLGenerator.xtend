package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.FieldObject
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.RuleApply

class WebEntityListComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[ entity |
			entity.generateComponentHTML
		]
	}
	
	def generateComponentHTML(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebListComponentName + '.html'
		generateFile(entityFile, entity.doGenerateEntityComponentHTML)
	}
	
	def CharSequence doGenerateEntityComponentHTML(Entity entity) {
		'''
		<div class="container">
		
		  	<div class="ui-g">
				«entity.generateEntityTitle»
				«entity.generateHTMLFilters»
				«entity.generateHTMLGrid»
				«entity.generateHTMLButtons»
				«entity.generateHTMLExtras»
			</div>
		  
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilters(Entity entity) {
		entity.generateHTMLFiltersWithAccordion
		// entity.generateHTMLFiltersWithPanel
	}
	
	def CharSequence generateHTMLFiltersWithAccordion(Entity entity) {
		'''
		
		<!-- Begin Filters -->
		<p-accordion class="ui-g-12">
			<p-accordionTab header="Filtro">
			
				<div class="ui-g">
					<div class="ui-g-12">
						«entity.slots.filter[!mapped].filter[it.hasListFilter].generateHTMLSlotsFilters»
					</div>
					
					<div>
						«entity.generateHTMLFilterSearchButton»
					</div>
				</div>
				
			
			</p-accordionTab>
		</p-accordion>
		<!-- End Filters -->
		'''
	}
	
	def CharSequence generateHTMLFiltersWithPanel(Entity entity) {
		'''
		
		<!-- Begin Filters -->
		<p-panel class="ui-g-12" header="Filtro"  [toggleable]="true" [collapsed]="true">
		
			<div class="ui-g">
				<div class="ui-g-12">
					«entity.slots.filter[!mapped].filter[it.hasListFilter].generateHTMLSlotsFilters»
				</div>
			</div>
			
			<p-footer>
				«entity.generateHTMLFilterSearchButton»
			</p-footer>
		
		</p-panel>
		<!-- End Filters -->
		'''
	}
	
	def CharSequence generateHTMLFilterSearchButton(Entity entity) {
		'''
		  <p-button label="Pesquisar" (click)="«entity.toWebEntityFilterSearchMethod»"></p-button>
		'''
	}
	
	def CharSequence generateHTMLGrid(Entity entity) {
		val slots = entity.slots.filter[!mapped].filter[it.isShowOnGrid]
		val hasSum = slots.exists[hasSumField]
		
		val ruleActions = entity.ruleActions
		val ruleGridRows = entity.ruleGridRows
		val ruleGridRowsWithCSS = ruleGridRows.filter[it.apply.hasCSS]
		
		
		'''
		
		<!-- Begin GRID -->
		<div class="ui-g-12" name="data-grid">
			<p-table selectionMode="single" [loading]="loading" [responsive]="true" [customSort]="true" [paginator]="true" 
				[value]="«entity.toEntityWebListItems»"
			    [rows]="«entity.toEntityListFilterName».«LIST_FILTER_PAGE_SIZE»" 
			    [totalRecords]="«entity.toEntityWebListItemsTotalElements»"
			    [lazy]="true" (onLazyLoad)="«entity.toEntityListOnLazyLoadMethod»($event)" >
			    «IF !ruleGridRowsWithCSS.empty»
			    «ruleGridRowsWithCSS.generateRuleGridRowsCSSLegend»
			    «ENDIF»
			    <ng-template pTemplate="header">
		            <tr>
		            	«slots.map[slot |
		            	val userClasses = slot.getUserWebClassesArray
		            	'''
	            		«IF slot.isOrderedOnGrid»
	            			<th«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF» «slot.buildGridColumnWidth»[pSortableColumn]="'«slot.fieldName»'">«slot.getTranslationKeyGridFunc»<p-sortIcon [field]="'«slot.fieldName»'"></p-sortIcon></th>
	            		«ELSE»
	            			<th«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF»>«slot.getTranslationKeyGridFunc»</th>
	            		«ENDIF»
		            	'''
		            ].join»
						<th style="width: 12em">Ações</th>
		            </tr>
		        </ng-template>
		        
			    <ng-template pTemplate="body" let-«entity.fieldName»>
		            <tr [pSelectableRow]="«entity.fieldName»">
		            	«slots.map[generateHTMLGridDataRow].join»
		              	<td class="kb-actions">
		              		<a pButton [routerLink]="['/«entity.toWebName»', «entity.fieldName».«entity.id.fieldName»]" icon="pi pi-pencil" pTooltip="Editar" tooltipPosition="top"></a>
		              		<!-- <button (click)="mostrarPagarConta(«entity.fieldName»)" pButton icon="pi pi-money"  pTooltip="Pagar esta conta" tooltipPosition="top"></button> -->
		              		<button (click)="«entity.toWebEntityListDeleteItem»(«entity.fieldName»)" pButton icon="pi pi-trash"  pTooltip="Excluir" tooltipPosition="top"></button>
		              		«ruleActions.map[it.generateRuleActions].join»
		              	</td>
		            </tr>
		        </ng-template>
		        
		        
		        <ng-template pTemplate="emptymessage" let-columns>
				    <tr>
				        <td [attr.colspan]="«slots.size + 1»">
				            Nenhum registro encontrado.
				        </td>
				    </tr>
				</ng-template>
				
				«IF hasSum»
				<ng-template pTemplate="footer">
					<tr>
						<td class="kb-sum-footer">Totais</td>
						«slots.tail.map[it.generateSumField].join»
						<td class="kb-sum-footer">«entity.buildEntityRuleWithSum»</td>
					</tr>
				</ng-template>
				«ENDIF»
			</p-table>
		</div>
		<!-- End GRID -->
		'''
	}
	
	def generateRuleGridRowsCSSLegend(Iterable<Rule> rules) {
		'''
		
		<ng-template pTemplate="caption">
			Legenda:
			«rules.map[it.apply.generateCSSLegend].join»
		</ng-template>
		
		'''
	}
	
	def generateCSSLegend(RuleApply apply) {
		var label = '<Sem legenda>'
		if (apply.hasLabel) {
			label = apply.label
		}
		'''
		<span «apply.getCSSValue('kb-conta-legenda')»>«label»</span>
		'''
	}
	
	def CharSequence buildGridColumnWidth(Slot slot) {
		if (slot.isDate) {
			'''style="width: 7em" '''
		}
		else if (slot.isMoney) {
			'''style="width: 8em" '''
		}
		else {
			''''''
		}
	}
	
	def CharSequence generateRuleActions(Rule rule) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val icon = rule.action?.actionButton?.icon ?: 'pi pi-cog' //gear
		val tooltip = rule.action?.actionButton?.tooltip ?: actionName
		
		'''
		<button pButton
		    [disabled]="!«rule.getRuleActionWhenName»(«entityVar»)"
		    (click)="«actionName»(«entityVar»)"
		    icon="«icon»"  tooltipPosition="top"
		    pTooltip="«tooltip»">
		</button>
		'''
	}
	
	def CharSequence buildEntityRuleWithSum(Entity entity) {
		val rule = entity.rulesWithTargetEnum.filter[it.ruleAsTargetEnum == RuleTarget.GRID_SUMROW_LAST_CELL].head
		if (rule === null) {
			return ''
		}
		
		val sbLabels = new StringBuilder
		val sbField = new StringBuilder
		var expression = rule.apply.sumFieldExpression
		var slot = expression.getLeftField.getField
		sbLabels.append(slot.getSumSlotLabelWithStyle)
		sbField.append(slot.getEntitySumFieldName)
		while (expression.getRightField !== null) {
			sbLabels.append(expression.getOperator.literal)
			sbField.concatSB(expression.getOperator.literal)
			
			expression = expression.getRightField
			
			slot = expression.getLeftField.getField
			sbLabels.append(slot.getSumSlotLabelWithStyle)
			sbField.concatSB(slot.getEntitySumFieldName)
		}
		
		'''(«sbLabels.toString»): {{ («sbField.toString») | currency:'BRL':'symbol':'1.2-2':'pt' }}'''
	}
	
	def String getSumSlotLabelWithStyle(Slot slot) {
		val label = slot?.sumField?.label ?: slot.label
		var stylled = label
		if (slot.hasSumField) {
			val sumField = slot.sumField
			if (sumField.hasStyleClass) {
				stylled = '''<span class="«sumField.styleClass»">«label»</span>'''
			}
			else if (sumField.hasStyleCss) {
				stylled = '''<span style="«sumField.styleCss»">«label»</span>'''
			}
		}
		stylled
	}
	
	def CharSequence applyRulesOnGrid(Entity entity) {
		if (!entity.hasRules) {
			return ''''''
		}
		if (entity.rulesWithTargetEnum.exists[it.ruleAsTargetEnum == RuleTarget.GRID_ROWS]) {
			return ''' [ngClass]="applyAndGetRuleGridRowStyleClass(«entity.fieldName»)"'''
		}
	}
	
	def CharSequence applyRuleOnGrid(Rule rule) {
		val expressions = newArrayList
		if (rule.when.expression.left.whenObject instanceof FieldObject) {
			val slot = (rule.when.expression.left.whenObject as FieldObject).getField
			expressions.add(slot.fieldName)
		}
		
		''''''
	}
	
	def CharSequence generateSumField(Slot slot) {
		'''
		«IF slot.hasSumField»<td«slot.generateSumFieldCSS»>«slot.generateSumFieldValue»</td>«ELSE»<td class="kb-sum-footer"></td>«ENDIF»
		'''
	}
	
	def CharSequence generateSumFieldCSS(Slot slot) {
		val sum = slot.sumField
		''' class="kb-sum-footer sumField«IF sum.hasStyleClass» «sum.styleClass»«ENDIF»"«IF sum.hasStyleCss» style="«sum.styleCss»"«ENDIF»'''
	}
	
	def CharSequence generateSumFieldValue(Slot slot) {
		'''«IF slot.sumField.hasLabel»«slot.sumField.label»: «ENDIF»{{ «slot.ownerEntity.toEntitySumFieldsName.toFirstLower».«slot.sumFieldName»«IF slot.isMoney» | currency:'BRL':'symbol':'1.2-2':'pt'«ENDIF» }}'''
	}
	
	def CharSequence generateHTMLExtras(Entity entity) {
		'''
		
		<!-- Begin Extras
		
		<p-dialog header="Pagar conta" [(visible)]="mostrarDialogPagarConta" [modal]="true" [responsive]="true" [width]="350" [minWidth]="200" [minY]="70"
		        [maximizable]="false" [baseZIndex]="10000">
		      <div>
		          <div>Conta: <strong>{{ contaPagar.descricao }}</strong></div>
		          <div>
		              <label style="display: block">Valor pago</label>
		              <input currencyMask [options]="{ prefix: '', thousands: '.', decimal: ',', allowNegative: false }"
		              [(ngModel)]="contaPagar.valorPago" pInputText type="text" name="contaPagarValorPago" ngModel placeholder="0,00">
		          </div>
		          <div>
		              <label style="display: block">Data pagamento</label>
		              <p-calendar name="contaPagarDataPagamento" dateFormat="dd/mm/yy"
		              [inline]="false" [readonlyInput]="false" [showIcon]="false"
		               [(ngModel)]="contaPagar.dataPagamento" ngModel></p-calendar>
		          </div>
		      </div>
		        <p-footer>
		            <button type="button" pButton icon="pi pi-check" (click)="executarPagarConta()" label="Pagar"></button>
		            <button type="button" pButton icon="pi pi-close" (click)="cancelarPagarConta()" label="Cancelar" class="ui-button-secondary"></button>
		        </p-footer>
		</p-dialog>
		
		End Extras -->
		'''
	}
	
	def CharSequence generateHTMLGridDataRow(Slot slot) {
		var fieldName = slot.entityFieldName
		if (slot.isNumber && slot.isGridShowNumberAsNegative) {
			fieldName = 'doShowNumberAsNegative(' + fieldName + ')'
		}
		val userClasses = slot.getUserWebClassesArray
		
		val hasStyleClass = slot.hasGridStyleClass
		'''
		<td«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF»«slot.ownerEntity.applyRulesOnGrid»«slot.buildBodyRowStyleCss»>
			«IF hasStyleClass»<div class="«slot.grid.styleClass»">«ENDIF»
			«IF slot.isDate»
			{{«fieldName» | date:'dd/MM/yyyy'}}
			«ELSEIF slot.isDateTime»
			{{«fieldName» | date:'dd/MM/yyyy HH:mm'}}
			«ELSEIF slot.isTime»
			{{«fieldName» | date:'HH:mm:ss'}}
			«ELSEIF slot.isMoney»
			{{«fieldName» | currency:'BRL':'symbol':'1.2-2':'pt' }}
			«ELSEIF slot.isBoolean»
			{{«fieldName»«slot.booleanValue» }}
			«ELSEIF slot.isEntity»
			{{«slot.webAutoCompleteFieldConverter»(«fieldName»)}}
			«ELSEIF slot.isEnum»
			«slot.getTranslationKeyFunc(fieldName + '?.toLowerCase()')»
			«ELSE»
			{{«fieldName»}}
			«ENDIF»
			«IF hasStyleClass»</div">«ENDIF»
		</td>
		'''
	}
	
	def CharSequence getBooleanValue(Slot slot) {
		val basicType = (slot.slotType as BasicTypeReference).basicType
		val bool = basicType as BooleanType
		
		'''? '«bool.displayTrue»': '«bool.displayFalse»'«»'''
	}
	
	def String buildBodyRowStyleCss(Slot slot) {
		if (slot.isMoney) {
			return ' class="kb-field-money"'
		}
		return ''
	}
	
	def CharSequence generateHTMLButtons(Entity entity) {
		'''
		
		<div class="ui-g-12 ui-md-2 ui-fluid">
			<a routerLink="/«entity.toWebName»/novo" pButton label="Novo registro"></a>
		</div>
		'''
	}
	
	def CharSequence generateHTMLSlotsFilters(Iterable<Slot> slots) {
		'''
		«slots.map[generateHTMLSlotFilter].join('')»
		'''
	}
	
	def CharSequence generateHTMLSlotFilter(Slot slot) {
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
			
			'''
			«IF isMany»
			«slot.generateHTMLFilterManyField»
			«ELSEIF isNotNull || isNull»
			
			«IF isNotNull»
			«slot.generateHTMLFilterIsNotNullField»
			«ENDIF»
			
			«IF isNull»
			«slot.generateHTMLFilterIsNullField»
			«ENDIF»
			
			«ELSEIF isBetween»
			
			«IF slot.isDate»
			«slot.generateHTMLFilterIsBetweenIsDateField»
			«ELSE»
			«slot.generateHTMLFilterIsBetween»
			«ENDIF»
			
			«ENDIF»
			'''
	}
	
	def CharSequence generateHTMLFilterIsBetweenIsDateField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="ui-g-12">
		
		    <div class="ui-g-12 ui-md-2 ui-fluid">
		        <label style="display: block">«slot.getFilterIsBetweenLabel(2)»</label>
		        <p-dropdown #«slot.toIsBetweenOptionsVarName» 
			        [options]="dateFilterIntervalDropdownItems" 
			        [(ngModel)]="«slot.toIsBetweenOptionsSelected»"
			        optionLabel="label" (click)="«slot.toIsBetweenOptionsOnClickMethod»(«slot.toIsBetweenOptionsVarName»)">
		        </p-dropdown>
		    </div>
		
		    <div class="ui-g-12 ui-md-2 ui-fluid">
		      	<label class="label-r">«slot.getFilterIsBetweenLabel(0)»</label>
		        <p-calendar name="«slot.toIsBetweenFromName»"
		        dateFormat="dd/mm/yy" [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenFromName»"></p-calendar>
		    </div>
		
		    <div class="ui-g-12 ui-md-2 ui-fluid">
		        <label class="label-l label-r">«slot.getFilterIsBetweenLabel(1)»</label>
		        <p-calendar name="«slot.toIsBetweenToName»" dateFormat="dd/mm/yy"
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenToName»"></p-calendar>
		    </div>
		    
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsBetween(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="ui-g-12">
		
		    <div class="ui-g-12 ui-md-2 ui-fluid">
		      	<label class="label-r">«slot.getFilterIsBetweenLabel(0)»</label>
		        <input pInputText type="text" name="«slot.toIsBetweenFromName»"
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenFromName»" />
		    </div>
		
		    <div class="ui-g-12 ui-md-2 ui-fluid">
		        <label class="label-l label-r">«slot.getFilterIsBetweenLabel(1)»</label>
		        <input pInputText type="text" name="«slot.toIsBetweenToName»" dateFormat="dd/mm/yy"
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenToName»" />
		    </div>
		    
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsNotNullField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="ui-g-12 ui-md-2 ui-fluid">
			<label style="display: block" class="label-l label-r">«slot.getIsNotNull_isNullLabel(0)»</label>
			<p-inputSwitch [(ngModel)]="«entity.toEntityListFilterName».«slot.isNotNullFieldName»"></p-inputSwitch>
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsNullField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="ui-g-12 ui-md-2 ui-fluid">
			<label style="display: block" class="label-l label-r">«slot.getIsNotNull_isNullLabel(1)»</label>
			<p-inputSwitch [(ngModel)]="«entity.toEntityListFilterName».«slot.isNullFieldName»"></p-inputSwitch>
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterManyField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="ui-g-12 ui-md-12 ui-fluid">
			<label class="label-r">«slot?.listFilter?.filterOperator?.label ?: slot.fieldName»</label>
			<p-autoComplete name="«slot.toAutoCompleteName»" 
			placeholder="Digite para pesquisar..." [dropdown]="true" 
			[(ngModel)]="«entity.toEntityListFilterName».«slot.fieldName»" [multiple]="true"
			[suggestions]="«slot.webAutoCompleteSuggestions»"
			(completeMethod)="«slot.webAutoCompleteMethod»($event)"
			field="«slot.fieldName»"></p-autoComplete>
		</div>
		'''
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		'''
		<div>
			<h1>«entity.translationKey.translationKeyFunc»</h1>
		</div>
		'''
	}
	
	
}