package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleWebUtils.*

import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.FieldObject
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.RuleApply
import java.util.ArrayList
import java.util.List

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
		val hasHideWebListActions = entity.getRulesGridActionsHideWebListActions.size > 0
		
		'''
		<div class="container">
			«entity.generateEntityTitle»
		
		  	<div class="ui-g">
				«entity.generateHTMLFilters»
				«IF !hasHideWebListActions»
				«entity.generateHTMLButtonsOnTop»
				«ENDIF»
				«entity.generateHTMLGrid»
				«IF !hasHideWebListActions»
				«entity.generateHTMLButtons»
				«ENDIF»
			</div>
			
			</p-panel>
		  
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilters(Entity entity) {
		entity.generateHTMLFiltersWithAccordion
		// entity.generateHTMLFiltersWithPanel
	}
	
	def CharSequence generateHTMLFiltersWithAccordion(Entity entity) {
		val ruleListFilterTitle = entity.getRuleListFilterTitle.head
		val title = if (ruleListFilterTitle !== null) ruleListFilterTitle.apply.title else 'Filtros'
		
		'''
		
		<!-- Begin Filters -->
		<p-accordion class="ui-g-12">
			<p-accordionTab header="«title»">
			
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
		  <p-button label="Aplicar os filtros e pesquisar" icon="pi pi-search" iconPos="left" (click)="«entity.toWebEntityFilterSearchMethod»"></p-button>
		'''
	}
	
	def CharSequence generateHTMLGrid(Entity entity) {
		val filteredSlots = entity.slots.filter[!mapped].filter[it.isShowOnGrid]
		val slots = new ArrayList()
		slots.addAll(filteredSlots)
		
		val hasSum = slots.exists[hasSumField]
		
		val ruleActions = entity.ruleActions
		val ruleGridRows = entity.ruleGridRows
		val ruleGridRowsWithCSS = ruleGridRows.filter[it.apply.hasCSS]
		
		val hasRulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD.size > 0
		val ruleFormWithDisableCUDMethodName = entity.toRuleFormWithDisableCUDMethodName
		
		val hasHideCUDWebListActions = entity.getRulesGridActionsHideCUDWebListActions.size > 0
		
		val hasHideWebListActions = entity.getRulesGridActionsHideWebListActions.size > 0
		
		var webActionsColumnWidth = '12em';
		val ruleWebActionsColumn = entity.getRulesGridActionsWebActionsColumn
		if (ruleWebActionsColumn !== null && !ruleWebActionsColumn.isEmpty) {
			val rule = ruleWebActionsColumn.head
			webActionsColumnWidth = rule.apply.webActionsColumn.width
		}
		
		// Adicionar colunas dinamicamente
		var rulesGridWithAddColumn = entity.getRulesGridWithAddColumn
		if (!rulesGridWithAddColumn.empty) {
			// User can write addcolumns in any order.
			rulesGridWithAddColumn = rulesGridWithAddColumn.sortBy[it.apply.addColumnExpression.position]
			
			//Adicionar novos pseudo slots
			rulesGridWithAddColumn.forEach[it | 
				val addColumn = it.apply.addColumnExpression
				val newSlotColumn = entity.createRuleSlot(addColumn.name, addColumn.title)
				newSlotColumn.web.styleClass = addColumn.styleClass
				newSlotColumn.grid.slotIsUnordered = true
				newSlotColumn.grid.styleClass = addColumn.styleClass
				newSlotColumn.grid.columnStyle = addColumn.styleCss
				newSlotColumn.grid.columnWidth = addColumn.columnWidth
				newSlotColumn.grid.columnAlign = addColumn.align
				
				slots.add(addColumn.position, newSlotColumn)
			]
		}
		
		var attrColSpan = slots.size
		if (!hasHideWebListActions) {
			attrColSpan++ // + 1 for actions column
		} 
		
		
		'''
		
		<!-- Begin GRID -->
		<div class="ui-g-12" name="data-grid">
			<p-table styleClass="kb-grid kb-grid-«entity.name.toLowerCase»" selectionMode="single" [loading]="tableLoading"
				[showCurrentPageReport]="true" [rowsPerPageOptions]="[5,10,50,100]"
				currentPageReportTemplate="Mostrando {first} até {last} de {totalRecords} registros."
				[responsive]="true" sortMode="multiple" [paginator]="true" [resizableColumns]="true"
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
	            			<th«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF» «slot.buildGridColumnStyle»[pSortableColumn]="'«slot.fieldName»'">«slot.getTranslationKeyGridFunc»<p-sortIcon [field]="'«slot.fieldName»'"></p-sortIcon></th>
	            		«ELSE»
	            			<th«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF» «slot.buildGridColumnStyle»>«slot.getTranslationKeyGridFunc»</th>
	            		«ENDIF»
		            	'''
		            ].join»
						«IF !hasHideWebListActions»<th style="width: «webActionsColumnWidth»">Ações</th>«ENDIF»
		            </tr>
		        </ng-template>
		        
			    <ng-template pTemplate="body" let-«entity.fieldName»>
		            <tr [pSelectableRow]="«entity.fieldName»">
		            	«val idx = new ArrayList<Integer>»
		            	«slots.map[it.generateHTMLGridDataRow(idx)].join»
		              	«IF !hasHideWebListActions»
		              	<td class="kb-actions">
		              		«IF hasHideCUDWebListActions»
		              		<!-- CUD actions hidden by rules -->
		              		«ELSE»
		              		<a pButton [routerLink]="['/«entity.toWebName»', «entity.fieldName».«entity.id.fieldName»]" icon="pi pi-pencil" pTooltip="Editar" tooltipPosition="top"></a>
		              		<button«IF hasRulesFormWithDisableCUD» [disabled]="«ruleFormWithDisableCUDMethodName»(«entity.fieldName»)"«ENDIF» (click)="«entity.toWebEntityListDeleteItem»(«entity.fieldName»)" pButton icon="pi pi-trash"  pTooltip="Excluir" tooltipPosition="top"></button>
		              		«ENDIF»
		              		«ruleActions.map[it.generateRuleActions(ruleActions)].join»
		              	</td>
		              	«ENDIF»
		            </tr>
		        </ng-template>
		        
		        
		        <ng-template pTemplate="emptymessage" let-columns>
				    <tr>
				        <td [attr.colspan]="«attrColSpan»">
				            Nenhum registro encontrado.
				        </td>
				    </tr>
				</ng-template>
				
				«IF hasSum»
				<ng-template pTemplate="footer">
					<tr>
						<td class="kb-sum-footer">Totais«IF hasHideWebListActions» «entity.buildEntityRuleWithSum»«ENDIF»</td>
						«slots.tail.map[it.generateSumField].join»
						«IF !hasHideWebListActions»<td class="kb-sum-footer">«entity.buildEntityRuleWithSum»</td>«ENDIF»
					</tr>
				</ng-template>
				
				<ng-template pTemplate="summary">
					«slots.tail.map[it.generateSumFieldForSummary].join»
					<div>Sumarização «entity.buildEntityRuleWithSum»</div>
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
	
	def CharSequence buildGridColumnStyle(Slot slot) {
		
		var columnWidth = if (slot.hasGridColumnWidth) slot.grid.columnWidth else ''
		if (!columnWidth.empty) {
			columnWidth = '''width: «columnWidth»;'''
		}
		else if (slot.isDate) {
			columnWidth = '''width: 7em;'''
		}
		else if (slot.isMoney) {
			columnWidth = '''width: 8em;'''
		}
		
		var columnAlign = if (slot.hasGridColumnAlign) slot.grid.columnAlign else '' 
		if (!columnAlign.empty) {
			columnAlign = '''text-align: «columnAlign»;'''
		} else if (slot.isMoney) {
			columnAlign = '''text-align: right;''' // Default for money column.
		}
		
		
		val sb = new StringBuilder
		var has = false
		sb.append('style="')
		if (slot.hasGridColumnStyle) {
			var columnStyle = slot.grid.columnStyle
			if (!columnStyle.endsWith(";"))
			columnStyle += ";"
			sb.append(columnStyle)
			has = true
		}
		
		if (!columnWidth.empty) {
			if (has) {
				sb.append(" ")				
			}
			sb.append(columnWidth)
			has = true
		}
		
		if (!columnAlign.empty) {
			if (has) {
				sb.append(" ")				
			}
			sb.append(columnAlign)
			has = true
		}
		
		sb.append('" ')
		
		if (has) {
			return sb.toString			
		}
		
		return ''
	}
	
	/*def CharSequence buildGridColumnWidth(Slot slot) {
		var columnWidth = if (slot.hasGridColumnWidth) slot.grid.columnWidth else ''
		
		if (!columnWidth.empty) {
			'''style="width: «columnWidth»" '''
		}
		else if (slot.isDate) {
			'''style="width: 7em" '''
		}
		else if (slot.isMoney) {
			'''style="width: 8em" '''
		}
		else {
			''''''
		}
	}*/
	
	def CharSequence generateRuleActions(Rule rule, Iterable<Rule> ruleActions) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val entityVar = entity.fieldName
		val icon = rule.action?.actionButton?.icon ?: 'pi pi-cog' //gear
		val tooltip = rule.action?.actionButton?.tooltip ?: actionName
		
		// https://github.com/valor-software/ngx-bootstrap/issues/3075
		// Ocorre o problema (flickering) quando o último tooltipPosition=top, por isso muda o último para left.
		val tooltipPosition = if (rule === ruleActions.last) 'left' else 'top' // Bug no tooltipPosition=top PrimeNG
		
		'''
		<button pButton
		    [disabled]="!«rule.getRuleActionWhenName»(«entityVar»)"
		    (click)="«actionName»(«entityVar»)"
		    icon="«icon»"  tooltipPosition="«tooltipPosition»"
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
		var expression = rule.apply.fieldMathExpression
		var slot = expression.getLeftField.getField
		sbLabels.append(slot.getSumSlotLabelWithStyle)
		sbField.append(slot.getEntitySumFieldName)
		var index = 0
		while (expression.getRightFieldByIndex(index) !== null) {
			val operator = expression.getOperatorByIndex(index)
			val operation = operator.literal
			sbLabels.append(operation)
			sbField.concatSB(operation)
			
			slot = expression.getRightFieldByIndex(index).field
			sbLabels.append(slot.getSumSlotLabelWithStyle)
			sbField.concatSB(slot.getEntitySumFieldName)
			index++
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
	
	def CharSequence generateSumFieldForSummary(Slot slot) {
		'''
		«IF slot.hasSumField»<div class="kb-mobile-block"><span«slot.generateSumFieldCSS(true)»>Soma "«slot.title»" «slot.generateSumFieldValue»</span></div>«ENDIF»
		'''
	}
	
	def CharSequence generateSumField(Slot slot) {
		'''
		«IF slot.hasSumField»<td«slot.generateSumFieldCSS»>«slot.generateSumFieldValue»</td>«ELSE»<td class="kb-sum-footer"></td>«ENDIF»
		'''
	}
	
	def CharSequence generateSumFieldCSS(Slot slot) {
		slot.generateSumFieldCSS(/*isSummary=*/false)
	}
	
	def CharSequence generateSumFieldCSS(Slot slot, boolean isSummary) {
		val sum = slot.sumField
		''' class="«IF !isSummary»kb-sum-footer sumField«ENDIF»«IF sum.hasStyleClass» «sum.styleClass»«ENDIF»"«IF sum.hasStyleCss» style="«sum.styleCss»"«ENDIF»'''
	}
	
	def CharSequence generateSumFieldValue(Slot slot) {
		var fieldName = slot.ownerEntity.toEntitySumFieldsName.toFirstLower + '.' + slot.sumFieldName
		
		if (slot.isGridShowNumberAsNegative) {
			fieldName = fieldName.toGridShowNumberAsNegative
		}
		
		'''«IF slot.sumField.hasLabel»(«slot.sumField.label»): «ENDIF»{{ «fieldName»«IF slot.isMoney» | «IF slot.isGridNoCurrencySimbol»number:'1.2-2'«ELSE»currency:'BRL':'symbol':'1.2-2':'pt'«ENDIF»«ENDIF» }}'''
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
	
	def CharSequence generateHTMLGridDataRow(Slot slot, List<Integer> idx) {
		val index = idx.size
		idx.add(index);
		var fieldName = slot.entityFieldName
		if (slot.isNumber && slot.isGridShowNumberAsNegative) {
			fieldName = fieldName.toGridShowNumberAsNegative
		}
		val userClasses = slot.getUserWebClassesArray
		
		val hasStyleClass = slot.hasGridStyleClass
		val hasDataIcon = slot.hasShowDataWithIcon
		val showDataWithIcon = slot.showDataWithIcon

		val rulesGridColumns = slot.ownerEntity.getRulesGridColumns
		var hasRulesGridColumnsForThisSlot = false
		var rulesGridColumnsGroup = 'default'
		if (!rulesGridColumns.isEmpty) {
			// Ou estão todos com range == null, ou respeita apenas os índices.
			hasRulesGridColumnsForThisSlot = (
				rulesGridColumns.exists[it.ruleAsRuleTargetEnum.range.isEmpty] &&  // Tem ao menos um item com range == null E
				!rulesGridColumns.exists[it.ruleAsRuleTargetEnum.range.size > 0] // NÃO tem nenhum item com range !== nulll
			) || // OU tem itens com range definido.
				rulesGridColumns.exists[it1 | it1.ruleAsRuleTargetEnum.range.exists[it2 | it2.equals(index)]]
				
			if (hasRulesGridColumnsForThisSlot) {
				val rule = rulesGridColumns.findFirst[it1 | it1.ruleAsRuleTargetEnum.range.exists[it2 | it2.equals(index)]]
				if (rule !== null) {
					rulesGridColumnsGroup = rulesGridColumnsGroup = rule.ruleAsRuleTargetEnum.group
				}
				
			}
		}
		
		'''
		<td«IF hasDataIcon» style="text-align: center"«ENDIF»«IF userClasses !== null» [ngClass]="«userClasses»"«ENDIF»«slot.ownerEntity.applyRulesOnGrid»«slot.buildBodyRowStyleCss»>
			<span «IF slot.ruled»style="float: left !important;" «ENDIF»class="ui-column-title">«slot.getTranslationKeyGridFunc»:</span>
			«IF hasStyleClass»<div class="«slot.grid.styleClass»">«ENDIF»
			«IF hasRulesGridColumnsForThisSlot»
			<div [ngClass]="«slot.ownerEntity.toRuleGridColumnsApplyStyleClassMethodCall(rulesGridColumnsGroup)»">
			«ENDIF»
			«IF slot.isDate»
			{{«fieldName» | date:'dd/MM/yyyy' }}
			«ELSEIF slot.isDateTime»
			{{«fieldName» | date:'dd/MM/yyyy HH:mm'}}
			«ELSEIF slot.isTime»
			{{«fieldName» | date:'HH:mm'}}
			«ELSEIF slot.isMoney»
			{{«fieldName» | «IF slot.isGridNoCurrencySimbol»number:'1.2-2'«ELSE»currency:'BRL':'symbol':'1.2-2':'pt'«ENDIF» }}
			«ELSEIF slot.isBoolean»
			{{«fieldName»«slot.booleanValue» }}
			«ELSEIF slot.isEntity»
			{{«slot.webAutoCompleteFieldConverter»(«fieldName»)}}
			«ELSEIF slot.isEnum»
			«slot.getTranslationKeyFunc(fieldName + '?.toLowerCase()')»
			«ELSEIF slot.isRuled»
			{{«slot.toRuleAddColumnGetValueMethodCall»}}
			«ELSE»
			«IF hasDataIcon»<i«IF 'true' == showDataWithIcon.onlyNotNullValue» *ngIf="«fieldName»"«ENDIF» class="«showDataWithIcon.icon»" style="font-size: «showDataWithIcon.iconSize»" [pTooltip]=«fieldName»></i>«ELSE»{{ «fieldName» }}«ENDIF»
			«ENDIF»
			«IF hasRulesGridColumnsForThisSlot»
			</div>
			«ENDIF»
			«IF hasStyleClass»</div">«ENDIF»
		</td>
		'''
	}
	
	def CharSequence getColumnData(Slot slot) {
		
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
	
	def CharSequence generateHTMLButtonsOnTop(Entity entity) {
		entity.generateHTMLButtons(true)
	}
	
	def CharSequence generateHTMLButtons(Entity entity) {
		entity.generateHTMLButtons(false)
	}
	
	def CharSequence generateHTMLButtons(Entity entity, boolean showOnTop) {
		val ruleFormCrudButtons = entity.getRuleFormCrudButtons
		
		val crudButtons = ruleFormCrudButtons?.apply?.crudButtons
		val buttonNew = crudButtons.buildCrudButtonNew(entity)
		
		'''
		
		<!-- Begin buttons -->
		<div class="ui-g-12 «IF showOnTop»crud-buttons-top kb-mobile-only«ELSE»crud-buttons-bottom«ENDIF»">
		  <div class="ui-g-12 ui-md-2 ui-fluid">
		    <a routerLink="/«entity.toWebName»/novo" pButton «buttonNew»></a>
		  </div>
		</div>
		<!-- End buttons -->
		
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
		
		val isEqualTo = slot.isEqualTo
		
			'''
			«IF isEqualTo»
			«slot.generateHTMLFilterIsEqualToField»
			«ENDIF»
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
		val styleClass = slot?.listFilter?.styleClass?.getStyleClass
		
		'''
		
		<div class="«slot.getWebClassForContainerFilter»">
		
		    <div class="ui-g-12 «styleClass» ui-fluid">
		        <label style="display: block">«slot.getFilterIsBetweenLabel(2)»</label>
		        <p-dropdown #«slot.toIsBetweenOptionsVarName» 
			        [options]="dateFilterIntervalDropdownItems" 
			        [(ngModel)]="«slot.toIsBetweenOptionsSelected»"
			        optionLabel="label" (click)="«slot.toIsBetweenOptionsOnClickMethod»(«slot.toIsBetweenOptionsVarName»)">
		        </p-dropdown>
		    </div>
		
		    <div class="ui-g-12 «styleClass» ui-fluid">
		      	<label class="label-r">«slot.getFilterIsBetweenLabel(0)»</label>
		        <p-calendar name="«slot.toIsBetweenFromName»"
		        dateFormat="dd/mm/yy" [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenFromName»"></p-calendar>
		    </div>
		
		    <div class="ui-g-12 «styleClass» ui-fluid">
		        <label class="label-l label-r">«slot.getFilterIsBetweenLabel(1)»</label>
		        <p-calendar name="«slot.toIsBetweenToName»" dateFormat="dd/mm/yy"
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenToName»"></p-calendar>
		    </div>
		    
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsBetween(Slot slot) {
		val entity = slot.ownerEntity
		val styleClass = slot?.listFilter?.styleClass?.getStyleClass
		
		'''
		
		<div class="«slot.getWebClassForContainerFilter»">
		
		    <div class="ui-g-12 «styleClass» ui-fluid">
		      	<label class="label-r">«slot.getFilterIsBetweenLabel(0)»</label>
		        <input pInputText type="text" name="«slot.toIsBetweenFromName»"
		        «IF slot.isNumber»
		        currencyMask [options]="{prefix: '', thousands: '.', decimal: ',', allowNegative: false}" placeholder="0,00"
		        «ENDIF»
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenFromName»" />
		    </div>
		
		    <div class="ui-g-12 «styleClass» ui-fluid">
		        <label class="label-l label-r">«slot.getFilterIsBetweenLabel(1)»</label>
		        <input pInputText type="text" name="«slot.toIsBetweenToName»"
		        «IF slot.isNumber»
		        currencyMask [options]="{prefix: '', thousands: '.', decimal: ',', allowNegative: false}" placeholder="0,00"
		        «ENDIF»
		        [(ngModel)]="«entity.toEntityListFilterName».«slot.toIsBetweenToName»" />
		    </div>
		    
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsNotNullField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="«slot.getWebClassForContainerFilter»">
			<label style="display: block" class="label-l label-r">«slot.getIsNotNull_isNullLabel(0)»</label>
			<p-inputSwitch [(ngModel)]="«entity.toEntityListFilterName».«slot.isNotNullFieldName»"></p-inputSwitch>
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsNullField(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		
		<div class="«slot.getWebClassForContainerFilter»">
			<label style="display: block" class="label-l label-r">«slot.getIsNotNull_isNullLabel(1)»</label>
			<p-inputSwitch [(ngModel)]="«entity.toEntityListFilterName».«slot.isNullFieldName»"></p-inputSwitch>
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterIsEqualToField(Slot slot) {
		val entity = slot.ownerEntity
		
		val isEntity = slot.isEntity
		// val fieldName = slot.fieldName
		
		// begin isEqualTo
		val pair = slot.getSlotNameAndTypeForWeb
		// val fieldType = pair.key
		val fieldName = pair.value
		// end isEqualTo
		
		val isInputText = slot.isNumber || slot.isString || slot.isUUID || isEntity
		
		val isHidden = slot.listFilter.hidden
		val isReadOnly = slot.listFilter.readOnly
		val inputType = if (isHidden) 'hidden' else 'text'		
		
		'''
		
		<div class="«slot.getWebClassForContainerFilter»">
			<label class="label-r«IF isHidden» hidden«ENDIF»">«slot?.listFilter?.filterOperator?.label ?: fieldName»</label>
			«IF isInputText»
			<input pInputText type="«inputType»"«IF isReadOnly» [disabled]="true"«ENDIF»
			«IF slot.isNumber»
			currencyMask [options]="{prefix: '', thousands: '.', decimal: ',', allowNegative: false}" placeholder="0,00"
			«ENDIF»
			[(ngModel)]="«entity.toEntityListFilterName».«fieldName»"/>
			«ELSEIF slot.isEnum»
			<p-dropdown«IF isHidden» class="hidden"«ENDIF»«IF isReadOnly» [disabled]="true"«ENDIF» [options]="«slot.webDropdownOptions»" placeholder="Selecione um item..."
			[(ngModel)]="«entity.toEntityListFilterName».«fieldName»"></p-dropdown>
			«ENDIF»
		</div>
		'''
	}
	
	def CharSequence generateHTMLFilterManyField(Slot slot) {
		val entity = slot.ownerEntity
		
		if (slot.isEnum) { // Many for enum, use p-multiSelect
			val pair = slot.getSlotNameAndTypeForWeb
			val fieldName = pair.value
			val isHidden = slot.listFilter.hidden
			val isReadOnly = slot.listFilter.readOnly
			
			'''
			
			<div class="«slot.getWebClassForContainerFilter»">
				<label class="label-r«IF isHidden» hidden«ENDIF»">«slot?.listFilter?.filterOperator?.label ?: fieldName»</label>
				<p-multiSelect«IF isHidden» class="hidden"«ENDIF»«IF isReadOnly» [disabled]="true"«ENDIF» [options]="«slot.webDropdownOptions»"
					filterPlaceHolder="Digite para filtrar..." defaultLabel="Selecione"
					[(ngModel)]="«entity.toEntityListFilterName».«fieldName»">
				</p-multiSelect>
			</div>
			'''
		}
		else { // Many for entity
			var styleClass = slot?.listFilter?.styleClass?.getStyleClass
			if ('ui-md-2' == styleClass) {
				styleClass = 'ui-md-12'
			}
			
			return '''
			
			<div class="«slot.getWebClassForContainerFilter»">
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
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		'''
		<p-panel>
			<p-header>
				<div class="kb-form-panel-header">«entity.translationKey.translationKeyFunc»</div>
			</p-header>
		
		'''
	}
	
	
}