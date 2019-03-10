package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

class WebEntityListComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	
	
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
	}
	
	def CharSequence doGenerateEntityComponentTS(Entity entity) {
		imports = new StringConcatenationExt()
		
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		val listFilterNameVar = entity.toEntityListFilterName
		
		val entitySumFieldsClassName = entity.toEntitySumFieldsName
		val getMethodEntitySumFields = 'get' + entitySumFieldsClassName
		
		val filterSlots = entity.slots.filter[it.hasListFilter]
		
		imports.add('''
		import { Component, OnInit } from '@angular/core';
		import {MessageService, ConfirmationService, LazyLoadEvent, SelectItem} from 'primeng/api';
		import { Dropdown } from 'primeng/dropdown';
		import * as moment from 'moment';
		''')
		
		imports.add('''import { «serviceName» } from './«entity.toEntityWebServiceName»';''')
		imports.add('''import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';''')
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { «entity.toEntityListFilterClassName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { SortField } from './«entity.toEntityWebModelName»';''')
		
		entity.slots.filter[it.isListFilterMany].forEach[
			imports.add('''import { «it.toAutoCompleteClassName» } from './«entity.toEntityWebModelName»';''')
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
		
		val component = entity.toEntityWebListComponentName
		
		val body = '''
		
		@Component({
		  selector: 'app-«component»',
		  templateUrl: './«component».html',
		  styleUrls: ['./«component».css']
		})
		
		export class «entity.toEntityWebListClassName» implements OnInit {
			
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
			
			/*
			«fieldName»: «dtoName»;
			totaisFiltroContaPagar = new TotaisFiltroContaPagar(0.0, 0.0);
			mostrarDialogPagarConta = false;
			*/
			
			constructor(
			    private «serviceVar»: «serviceName»,
			    private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»,
			    private confirmation: ConfirmationService,
			    private messageService: MessageService
			) { }
			
			ngOnInit() {
		    	this.«listFilterNameVar».sortField = new SortField('«entity.defaultOrderedField»', 1); // asc
				«IF !filterSlots.filter[it.isBetween && it.isDate].empty»
				this.initializeDateFilterIntervalDropdownItems();
				«««filterSlots.filter[it.isBetween && it.isDate].map['''this.«it.toIsBetweenOptionsOnClickMethod»(null);'''].join»
				«ENDIF»
				«IF !filterSlots.empty»
				«filterSlots.generateFilterSlotsInitialization»
				«ENDIF»
			    // this.«fieldName» = new «dtoName»();
		        // this.contaPagar.dataPagamento = moment().toDate();
			}
			
			«entity.toEntityListListMethod»(pageNumber = 0) {
			    this.«listFilterNameVar».pageNumber = pageNumber;
			    this.«serviceVar»
			    .«entity.toEntityListListMethod»(this.«listFilterNameVar»)
			    .then(result => {
			      this.«entity.toEntityWebListItems» = result.items;
			      this.«entity.toEntityWebListItemsTotalElements» = result.totalElements;
			    });
				
				«IF entity.hasSumFields»
				this.«getMethodEntitySumFields»();
				«ENDIF»
			}
			
			«IF entity.hasSumFields»
			«getMethodEntitySumFields»() {
			    this.«serviceVar».«getMethodEntitySumFields»(this.«listFilterNameVar»)
				.then(response => {
				  this.«entitySumFieldsClassName.toFirstLower» = response;
				})
				.catch(error => {
				  this.showError('Erro ao buscar totais:' + error);
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
			        this.«serviceVar».delete(«fieldName».id)
			        .then(() => {
			          this.showSuccess('Registro excluído!');
			          this.«entity.toEntityListListMethod»(0);
			        })
			        .catch((e) => {
			          this.showError('Erro ao excluir registro: ' + e);
			        });
			      }
			    });
			}
			
			«entity.toEntityListOnLazyLoadMethod»(event: LazyLoadEvent) {
			    if (event.sortField) {
			      this.«listFilterNameVar».sortField = new SortField(event.sortField, event.sortOrder);
			    } else {
			      this.«listFilterNameVar».sortField = new SortField('«entity.defaultOrderedField»', 1); // asc
			    }
			    const pageNumber = event.first / event.rows;
			    this.«entity.toEntityListListMethod»(pageNumber);
			}
			
			«filterSlots.filter[isListFilterMany].map[generateAutoCompleteMethod].join»
			
			«entity.slots.filter[isEntity].map[generateAutoCompleteFieldConverter].join»
			
			«IF !filterSlots.filter[it.isBetween && it.isDate].empty»
			private initializeDateFilterIntervalDropdownItems() {
				this.dateFilterIntervalDropdownItems = [
				    {label: 'Hoje', value: '0'},
				    {label: 'Amanhã', value: '1'},
				    {label: 'Esta semana', value: '2'},
				    {label: 'Semana que vem', value: '3'},
				    {label: 'Este mês', value: '4'},
				    {label: 'Mês que vem', value: '5'},
				    {label: 'Este ano', value: '6'},
				    {label: 'Ano que vem', value: '7'},
				    // Passado
				    {label: 'Ontem', value: '8'},
				    {label: 'Semana passada', value: '9'},
				    {label: 'Mês passado', value: '10'},
				    {label: 'Ano passado', value: '11'},
				    {label: 'Personalizado', value: '99'}
				  ];
			}
			
			«filterSlots.filter[isBetween].map[generatePeriodIntervalSelectMethod].join»
			«ENDIF»
			
			public showSuccess(msg: string) {
			    this.messageService.add({severity: 'success', summary: 'Successo', detail: msg});
			}
			
			public showError(msg: string) {
			    this.messageService.add({severity: 'error', summary: 'Erro', detail: msg});
			}
			
			«buildTranslationMethod(service)»
			
			«addExtras()»
		}
		'''
		
		val source = imports.ln.toString + body
		source
	}
	
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
		      this.showError('Erro ao buscar registros com o termo: ' + query);
		    });
		}
		
		'''
	}
	
	def CharSequence generateAutoCompleteFieldConverter(Slot slot) {
		val entity = slot.asEntity
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		'''
		«IF !resultSlots.isEmpty»
		«slot.webAutoCompleteFieldConverter»(«slot.fieldName»: «entity.toAutoCompleteName») {
			return «resultSlots.map['''«slot.fieldName».«it.fieldName»'''].join(" + ' - ' + ")»;
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
			
		'''
		«IF isMany»
		«slot.webAutoCompleteSuggestions»: «slot.toAutoCompleteClassName»[];
		«ELSEIF isNotNull || isNull»
		
		«IF isNotNull»
		«ENDIF»
		
		«IF isNull»
		«ENDIF»
		
		«ELSEIF isBetween»
		
		«IF slot.isDate»
		«slot.toIsBetweenOptionsSelected»: SelectItem = {label: 'Este ano', value: '6'};
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
			
		'''
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
		      this.showError('Erro ao buscar totais:' + erro);
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
		      this.showSuccess(`A conta ${contaPagar.descricao} foi paga.`);
		      this.contaPagarList(0);
		    })
		    .catch(erro => {
		      this.showError('Erro ao pagar a conta: ' + erro);
		    });
		}
		*********************/
		'''
	}
	
	
}